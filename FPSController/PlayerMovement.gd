class_name Player extends CharacterBody3D
@onready var input_component: InputComponent = $InputComponent
@onready var camera_component: CameraComponent = $CameraComponent

@export var look_sensitivity : float = 0.004;
@export var controller_look_sensitivity := 0.05;
@export var ground_accel = 14.0;
@export var ground_deccel = 10.0;
@export var ground_friction := 6.0;

@export var jump_velocity := 6.0;
@export var auto_bhop := true;
@export var walk_speed := 7.0;
@export var sprint_speed := 8.5;

@export var air_cap := 1;
@export var air_acccel := 800.0;
@export var air_move_speed := 500.0;

@export var coyote_time := 0.2;
@export var coyote_time_info := [Vector3.ZERO, 0.];

const MAX_STEP_HEIGHT = 0.5;
var _snapped_to_stairs_last_frame := false
var _last_frame_was_on_floor := -INF

const CAMERA_WALLRUN_TILT_ANGLE : int = 10;

var _cur_controller_look = Vector2()

enum COYOTE_TIME_INDEXES {
	WallNormal,
	TimeLeft
}

var wish_dir := Vector3.ZERO;

func _ready() -> void:
	
	for child in %WorldModel.find_children("*", "VisualInstance3D"):
		child.set_layer_mask_value(1, false);
		child.set_layer_mask_value(2, true);
	
	camera_component.camera = %Camera3D;
	camera_component.camera_smooth = %CameraSmooth
	
	pass


#region helpers

func get_move_speed() -> float:
	return sprint_speed if Input.is_action_pressed("sprint") else walk_speed

func is_surface_too_steep(normal : Vector3) -> bool:
	return normal.angle_to(Vector3.UP) > self.floor_max_angle;

func _run_body_test_motion(from : Transform3D, motion : Vector3, result = null) -> bool:
	
	if not result: PhysicsTestMotionParameters3D.new();
	var params = PhysicsTestMotionParameters3D.new();
	
	params.from = from;
	params.motion = motion;
	return PhysicsServer3D.body_test_motion(self.get_rid(), params, result);

#endregion

#region Movement Features

func player_jump(wall_normal : Vector3 = Vector3.ZERO) -> bool:
		
	var on_wall = wall_normal != Vector3.ZERO;
	
	if input_component.jump_just_pressed() or (!on_wall and auto_bhop and Input.is_action_pressed("jump")):
			
			input_component.jump_buffer = 0.;
			
			if on_wall:
				self.velocity += wall_normal * jump_velocity;
			
			self.velocity.y += jump_velocity;
			return true;
	
	return false;

#endregion

#region Camera Control

func _unhandled_input(event: InputEvent) -> void:
	
	input_component.capture_mouse(event);	
		
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			
			rotate_y(-event.relative.x * look_sensitivity)
			camera_component.rotate_x(-event.relative.y * look_sensitivity, deg_to_rad(-90), deg_to_rad(90))
		

func _handle_controller_look_input(delta : float):
	
	_cur_controller_look = input_component.controller_target_look;
	
	rotate_y(-_cur_controller_look.x * controller_look_sensitivity)
	camera_component.rotate_x(_cur_controller_look.y * controller_look_sensitivity, deg_to_rad(-90), deg_to_rad(90))

#endregion

#region Air Physics

func clip_velocity(normal: Vector3, overbounce : float, delta : float) -> void:
	
	var backoff := self.velocity.dot(normal) * overbounce
	
	if backoff >= 0: return
	
	var change := normal * backoff
	self.velocity -= change
	
	var adjust := self.velocity.dot(normal)
	if adjust < 0.0:
		self.velocity -= normal * adjust
		

func can_wall_run(wall_normal: Vector3) -> bool:

	# Ignore vertical velocity (falling shouldn't trigger wall run)
	var horizontal_velocity = self.velocity
	horizontal_velocity.y = 0

	if horizontal_velocity.length() < 2.0:
		return false

	# Direction along the wall
	var wall_tangent = wall_normal.cross(Vector3.UP).normalized()

	# How much the player moves along the wall
	var along_wall = abs(horizontal_velocity.normalized().dot(wall_tangent))

	# Require the player to be mostly moving along the wall
	if along_wall > 0.6:
		return true

	return false
	

func _handle_air_physics(delta: float) -> void:
	
	var cur_speed_in_wish_dir = self.velocity.dot(wish_dir)
	
	var capped_speed = min((air_move_speed * wish_dir).length(), air_cap)
	
	var add_speed_till_cap = capped_speed - cur_speed_in_wish_dir;
	if add_speed_till_cap > 0:
		var accel_speed = air_acccel * air_move_speed * delta
		accel_speed = min(accel_speed, add_speed_till_cap)
		self.velocity += accel_speed * wish_dir;
	
	var wall_running = 0;
	
	if is_on_wall():
		
		var wall_normal = get_wall_normal();
		
		if can_wall_run(wall_normal):
			
			if self.velocity.y < 0: wall_running = 1
			
			coyote_time_info = [wall_normal, coyote_time]
			
			var tilt_dir = -sign(wall_normal.dot(global_transform.basis.x))
			camera_component.set_camera_tilt(deg_to_rad(CAMERA_WALLRUN_TILT_ANGLE) * tilt_dir)
			
		if is_surface_too_steep(wall_normal):
			self.motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
		else:
			self.motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
		
		clip_velocity(wall_normal, 1, delta)
	
	self.velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta * (1 - wall_running * 0.8)
	
	pass

#endregion

#region stairs code
func _snap_down_to_stairs_check() -> void:
	var did_snap := false
	# Modified slightly from tutorial. I don't notice any visual difference but I think this is correct.
	# Since it is called after move_and_slide, _last_frame_was_on_floor should still be current frame number.
	# After move_and_slide off top of stairs, on floor should then be false. Update raycast incase it's not already.
	%StairsBelowRayCast3D.force_raycast_update()
	var floor_below : bool = %StairsBelowRayCast3D.is_colliding() and not is_surface_too_steep(%StairsBelowRayCast3D.get_collision_normal())
	var was_on_floor_last_frame = Engine.get_physics_frames() == _last_frame_was_on_floor
	if not is_on_floor() and velocity.y <= 0 and (was_on_floor_last_frame or _snapped_to_stairs_last_frame) and floor_below:
		var body_test_result = KinematicCollision3D.new()
		if self.test_move(self.global_transform, Vector3(0,-MAX_STEP_HEIGHT,0), body_test_result):
			camera_component._save_camera_pos_for_smoothing()
			var translate_y = body_test_result.get_travel().y
			self.position.y += translate_y
			apply_floor_snap()
			did_snap = true
	_snapped_to_stairs_last_frame = did_snap


func _snap_up_stairs_check(delta) -> bool:
	if not is_on_floor() and not _snapped_to_stairs_last_frame: return false
	# Don't snap stairs if trying to jump, also no need to check for stairs ahead if not moving
	if self.velocity.y > 0 or (self.velocity * Vector3(1,0,1)).length() == 0: return false
	var expected_move_motion = self.velocity * Vector3(1,0,1) * delta
	var step_pos_with_clearance = self.global_transform.translated(expected_move_motion + Vector3(0, MAX_STEP_HEIGHT * 2, 0))
	# Run a body_test_motion slightly above the pos we expect to move to, towards the floor.
	#  We give some clearance above to ensure there's ample room for the player.
	#  If it hits a step <= MAX_STEP_HEIGHT, we can teleport the player on top of the step
	#  along with their intended motion forward.
	var down_check_result = KinematicCollision3D.new()
	if (self.test_move(step_pos_with_clearance, Vector3(0,-MAX_STEP_HEIGHT*2,0), down_check_result)
	and (down_check_result.get_collider().is_class("StaticBody3D") or down_check_result.get_collider().is_class("CSGShape3D"))):
		var step_height = ((step_pos_with_clearance.origin + down_check_result.get_travel()) - self.global_position).y
		# Note I put the step_height <= 0.01 in just because I noticed it prevented some physics glitchiness
		# 0.02 was found with trial and error. Too much and sometimes get stuck on a stair. Too little and can jitter if running into a ceiling.
		# The normal character controller (both jolt & default) seems to be able to handled steps up of 0.1 anyway
		if step_height > MAX_STEP_HEIGHT or step_height <= 0.01 or (down_check_result.get_position() - self.global_position).y > MAX_STEP_HEIGHT: return false
		%StairsAheadRayCast3D.global_position = down_check_result.get_position() + Vector3(0,MAX_STEP_HEIGHT,0) + expected_move_motion.normalized() * 0.1
		%StairsAheadRayCast3D.force_raycast_update()
		if %StairsAheadRayCast3D.is_colliding() and not is_surface_too_steep(%StairsAheadRayCast3D.get_collision_normal()):
			camera_component._save_camera_pos_for_smoothing()
			self.global_position = step_pos_with_clearance.origin + down_check_result.get_travel()
			apply_floor_snap()
			_snapped_to_stairs_last_frame = true
			return true
	return false
#endregion 

#region Ground Physics

func _handle_ground_physics(delta: float) -> void:
	
	var cur_speed_in_wish_dir = self.velocity.dot(wish_dir)
	var add_speed_till_cap = get_move_speed() - cur_speed_in_wish_dir
	
	if add_speed_till_cap > 0:
		var accel_speed = ground_accel * delta * get_move_speed()
		accel_speed = min(accel_speed, add_speed_till_cap)
		self.velocity += accel_speed * wish_dir
		
	var control = max(self.velocity.length(), ground_deccel)
	var drop = control * ground_friction * delta
	var new_speed = max(self.velocity.length() - drop, 0.0)
	
	if self.velocity.length() > 0:
		new_speed /= self.velocity.length()
	self.velocity *= new_speed
	
	camera_component._headbob_effect(delta, self.velocity.length());
	pass

#endregion

func _physics_process(delta: float) -> void:
	
	var on_floor = is_on_floor() or _snapped_to_stairs_last_frame;
	if on_floor: _last_frame_was_on_floor = Engine.get_physics_frames()
	
	camera_component.set_camera_tilt(0.);

	
	input_component.update(delta);
	
	var input_dir = input_component.input_dir;
	wish_dir = self.global_transform.basis * Vector3(input_dir.x, 0., input_dir.y)
	
	if on_floor:
		
		coyote_time_info = [Vector3.ZERO, coyote_time]
			
		_handle_ground_physics(delta)
	else:
		_handle_air_physics(delta)
	
	if coyote_time_info[COYOTE_TIME_INDEXES.TimeLeft] > 0. : 
		if player_jump(coyote_time_info[COYOTE_TIME_INDEXES.WallNormal]) :	
			coyote_time_info[COYOTE_TIME_INDEXES.TimeLeft] = 0.;
			
	coyote_time_info[COYOTE_TIME_INDEXES.TimeLeft] = clamp(
		coyote_time_info[COYOTE_TIME_INDEXES.TimeLeft], 
		0, 
		coyote_time_info[COYOTE_TIME_INDEXES.TimeLeft] - delta)
	
	
	if not _snap_up_stairs_check(delta):
	
		move_and_slide();
		_snap_down_to_stairs_check();
	
	camera_component.update(delta);
	camera_component._slide_camera_smooth_back_to_origin(delta, self.velocity.length(), get_move_speed())
	pass

func _process(delta: float) -> void:

	_handle_controller_look_input(delta)

	pass
