class_name PlayerClass extends DynamicCharacterBody

@onready var camera_component: CameraComponent = $CameraComponent
#@onready var rocket_launcher_component: RocketLauncherComponent = $RocketLauncherComponent
@onready var kick_module: KickModule = $KickModule
@onready var weapon_manager: WeaponManager = $WeaponManager
@onready var telekinesis_component: TekelinesisComponent = $TelekinesisComponent

@onready var personal_space_area: Area3D = %PersonalSpaceArea
@onready var personal_space_shape: CollisionShape3D = %PersonalSpaceShape
@onready var original_personal_space_height = personal_space_shape.shape.height;


@export var look_sensitivity : float = 0.004;
@export var controller_look_sensitivity := 0.05;
@export var ground_accel = 14.0;
@export var ground_deccel = 10.0;
@export var ground_friction := 6.0;
var no_decell := 0.0;

@export var max_spd := 64.0;

@export var jump_velocity := 6.0;
@export var auto_bhop := true;
@export var walk_speed := 7.0;
@export var sprint_speed := 8.5;

@export var air_cap := 1;
@export var air_acccel := 800.0;
@export var air_move_speed := 500.0;

@export var coyote_time := 0.2;
@export var coyote_time_info := [Vector3.ZERO, 0.];

@export_group("Dash")
@export var dash_speed := 15.0
@export var dash_ground_duration := 0.3
@export var dash_air_duration := 0.2
@export var dash_jump_velocity := 8.0
@export var max_air_dashes := 1
@export var raycast_distance := 3.0

@onready var _original_capsule_height = $CollisionShape3D.shape.height;
const CROUCH_TRANSLATE = 0.7;
const CROUCH_JUMP_ADD = CROUCH_TRANSLATE * 0.9;
const CROUCH_MIN_SPEED = 10;
var is_crouched := false;
var crouch_wish := false;
var crouchable := true;
var static_crouch_y := false;



var was_crouched_last_frame := false;

# dash stuff
enum DashState { READY_TO_DASH = 1, GROUND_DASH = 2, AIR_DASH = 3, COOLDOWN = 4 }
enum DashType { NONE, GROUND_FLAT, GROUND_SLOPE, AIR }
var dash_state: DashState = DashState.READY_TO_DASH
var dash_ready: bool = true
var dash_time_remaining: float = 0.0
var dash_start_time: float = 0.0
var air_dash_count: int = 0
var dash_jump_requested: bool = false
var dash_jump_consumed: bool = false
var last_dash_type: DashType = DashType.NONE
var _was_on_floor_last_frame: bool = true

const MAX_STEP_HEIGHT = 0.5;
var _snapped_to_stairs_last_frame := false
var _last_frame_was_on_floor := -INF

const CAMERA_WALLRUN_TILT_ANGLE : int = 10;

var _cur_controller_look = Vector2()

enum COYOTE_TIME_INDEXES {
	WallNormal,
	TimeLeft
}

enum MOVEMENT_STATES {
	normal,
	crouch,
	wallrun
}

var movement_state : int = MOVEMENT_STATES.normal;


var wish_dir := Vector3.ZERO;
var crouch_dir := Vector3.ZERO;
var temp_crouch_dir := Vector3.ZERO;

func _ready() -> void:
	
	print("ground_accel at ready: ", ground_accel);
	health_component = $HealthComponent;
	
	add_to_group("player")
	
	LevelController.player = self;
	LevelController.player_attack_origin = %AttackOrigin;
	LevelController.player_camera = %Camera3D;
	
	for child in %WorldModel.find_children("*", "VisualInstance3D"):
		child.set_layer_mask_value(1, false);
		child.set_layer_mask_value(2, true);
	
	camera_component.camera = %Camera3D;
	camera_component.camera_smooth = %CameraSmooth
	camera_component.camera_tilt = %CameraTilt
	camera_component.shader_rect = %ColorRect;
	
	health_component.setup(100, false) # useless for now
	health_component.connect("died", on_death)
	
	var dual = LevelController.DualMacTen.new();
	weapon_manager.add_weapon(dual);
	
	pass


func on_death() -> void:
	LevelController.player_died();

#region crouch/slide

func force_uncrouch() -> void:
	crouch_wish = false;
	crouchable = false;

func change_crouch_dir(dir : Vector3) -> void:
	crouch_dir = dir.normalized();
	temp_crouch_dir = Vector3.ZERO;

func _handle_crouch(delta) -> void:
	
	#if input_component.just_crouched() : crouch_wish = !crouch_wish
	# if is_crouched != crouch_wish:
	
	var res = self.test_move(self.transform, Vector3(0, CROUCH_TRANSLATE * 1.2, 0));
	
	crouchable = crouchable or !InputController.is_crouching();
	
	if crouchable and InputController.is_crouching():
		
		if !is_crouched:
			is_crouched = true
			
			var dir = MovementUtils.get_look_direction_vector(%Camera3D);
			if !MovementUtils.really_on_floor(self) and dir.dot(Vector3.DOWN) >= 0 : 
				change_crouch_dir(dir);
			else:
				change_crouch_dir(MovementUtils.get_horizontal_vector(dir));
			
			movement_state = MOVEMENT_STATES.crouch
			
	elif is_crouched and not res:
		is_crouched = false;
		static_crouch_y = false;
		movement_state = MOVEMENT_STATES.normal
		change_crouch_dir(Vector3.ZERO)
	
	var translate_y_if_possible = 0.0;
	if(was_crouched_last_frame != is_crouched and !MovementUtils.really_on_floor(self)):
		translate_y_if_possible = CROUCH_JUMP_ADD if is_crouched else -CROUCH_JUMP_ADD
		
	if translate_y_if_possible != 0:
		var result = KinematicCollision3D.new();
		self.test_move(self.transform, Vector3(0, translate_y_if_possible, 0), result)
		self.position.y += result.get_travel().y
		%Head.position.y -= result.get_travel().y
		%Head.position.y = clampf(%Head.position.y, -CROUCH_TRANSLATE, 0)
	
	%Head.position.y = move_toward(%Head.position.y, -CROUCH_TRANSLATE if is_crouched else 0., 7.0 * delta)
	$CollisionShape3D.shape.height = _original_capsule_height - CROUCH_TRANSLATE if is_crouched else _original_capsule_height
	$CollisionShape3D.position.y = $CollisionShape3D.shape.height / 2
	
	personal_space_shape.shape.height = original_personal_space_height - CROUCH_TRANSLATE if is_crouched else _original_capsule_height

	was_crouched_last_frame = is_crouched;


func slide_player() -> void:
	
	var horizontal_velocity = MovementUtils.get_horizontal_vector(self.velocity);
	var spd = max(horizontal_velocity.length(), CROUCH_MIN_SPEED);
	
	self.velocity.x = spd * (temp_crouch_dir.x if temp_crouch_dir != Vector3.ZERO else crouch_dir.x);
	
	var y_dir = (temp_crouch_dir.y if temp_crouch_dir != Vector3.ZERO else crouch_dir.y);
	
	if static_crouch_y :
		self.velocity.y = spd * y_dir;
	else:
		
		#Don't add forever, there's a maximum.
		#This is to keep the "ground pound" mechanic while not making it absolutely fucking broken lmao.
		var max_val = abs(spd * y_dir) * 5.;
		if abs(self.velocity.y) < max_val:
			self.velocity.y = clampf(self.velocity.y + spd * y_dir, -max_val, max_val);
		
	self.velocity.z = spd * (temp_crouch_dir.z if temp_crouch_dir != Vector3.ZERO else crouch_dir.z);

#endregion

#region helpers

func get_move_speed() -> float:
	return sprint_speed if Input.is_action_pressed("sprint") else walk_speed

#endregion

#region Movement Features

var jump_frame := 0;
const JUMP_LOCK_FRAMES = 1;
func player_jump(wall_normal : Vector3 = Vector3.ZERO) -> bool:
		
	var on_wall = wall_normal != Vector3.ZERO;
	var frame = Engine.get_physics_frames();
	if InputController.jump_pressed() or (!on_wall and auto_bhop and Input.is_action_pressed("jump")):
			
			#For some reason, the frame AFTER the player jumps, they are still considered on the floor.
			#If the player jumps exactly on this second frame, the game lets them jump again, which we don't want.
			#This line takes care of that. It returns true so the coyote time is reset.
			#If the code for the true changes, we might need to add like an enum to tell the returns apart or something, but for now it's fine.
			if frame - jump_frame <= JUMP_LOCK_FRAMES : return true;
			
			
			jump_frame = frame;
			InputController.reset_jump_buffer();
			
			if self.velocity.y < 0 : self.velocity.y = 0;
			
			var camera_dir = MovementUtils.get_look_direction_vector(LevelController.player_camera);
			var jump_dir = camera_dir;
			var vertical_dir = Vector3(0., 1., 0.);
			
			if wall_normal.dot(camera_dir) < 0.:
				jump_dir = camera_dir.bounce(wall_normal);
				vertical_dir = vertical_dir.bounce(wall_normal);
			
			#If the camera angle is too close to the velocity direction (which will be the tangent of the wall).
			#Then increase the camera_dir until it's further away.
			
			if on_wall:
	
				var tangent = wall_normal.cross(Vector3.UP).normalized();
				var max_angle = deg_to_rad(60.0) # your limit
				var angle = camera_dir.angle_to(wall_normal)

				if angle > max_angle:
					# Axis to rotate around (stay on wall plane)
					var axis = wall_normal.cross(jump_dir).normalized()

					# Clamp by rotating wall_normal toward camera_dir
					jump_dir = wall_normal.rotated(axis, max_angle).normalized()
				
				var horizontal_spd = MovementUtils.get_horizontal_vector(velocity).length();
				var res_spd = jump_dir * max(abs(horizontal_spd), jump_velocity)
				
				
				self.velocity.x = res_spd.x;
				self.velocity.z = res_spd.z;
				
				self.velocity += vertical_dir * jump_velocity * 0.8;

	
				if is_wall_running(): 
					stop_wall_running(true)

			else:
				self.velocity.y += jump_velocity;
			
			if is_crouched:
				
				if on_wall:
					change_crouch_dir(MovementUtils.get_horizontal_vector(self.velocity.normalized()));
				else:
					change_crouch_dir(MovementUtils.get_horizontal_vector(camera_dir));
					
				slide_player();
			
			static_crouch_y = false;
			
			return true;
	
	return false;

#endregion

#region Camera Control

func _unhandled_input(event: InputEvent) -> void:
	
	InputController.capture_mouse(event);	
		
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			
			rotate_y(-event.relative.x * look_sensitivity * GameJuice.get_time_scale())
			camera_component.rotate_x(-event.relative.y * look_sensitivity * GameJuice.get_time_scale(), deg_to_rad(-90), deg_to_rad(90))
		

func _handle_controller_look_input(delta : float):
	
	_cur_controller_look = InputController.controller_target_look;
	
	rotate_y(-_cur_controller_look.x * controller_look_sensitivity)
	camera_component.rotate_x(_cur_controller_look.y * controller_look_sensitivity, deg_to_rad(-90), deg_to_rad(90))

#endregion

#region Air Physics
		
#region wall_run
	
var wall_run_normal := Vector3.ZERO;
var wall_run_dir := Vector3.ZERO; 
		
func can_wall_run(wall_normal: Vector3) -> bool:

	# Ignore vertical velocity (falling shouldn't trigger wall run)
	var horizontal_velocity = MovementUtils.get_horizontal_vector(self.velocity)

	#if horizontal_velocity.length() < 4.0:
		#return false

	# Direction along the wall
	#var wall_tangent = wall_normal.cross(Vector3.UP).normalized()

	# How much the player moves along the wall
	#var along_wall = abs(horizontal_velocity.normalized().dot(wall_tangent))

	# Require the player to be mostly moving along the wall
	#if along_wall > 0.6:
		#return true

	return !MovementUtils.really_on_floor(self);

func check_wall_run(delta : float) -> void:
	
	var chain = get_active_chain()
	var wall_normal : Vector3
	var valid_wall := false

	if chain.active:
		wall_normal = -chain.normal
		valid_wall = true

	elif is_on_wall():
		wall_normal = get_wall_normal()
		valid_wall = can_wall_run(wall_normal)
	elif is_wall_running():
		var body_test_result = KinematicCollision3D.new()
		if test_move(global_transform, -wall_run_normal, body_test_result):
			wall_normal = body_test_result.get_normal()
			valid_wall = true;
			

	if valid_wall:
			
		movement_state = MOVEMENT_STATES.wallrun
		wall_run_normal = wall_normal
		wall_run_dir = wall_run_normal.cross(Vector3.UP).normalized()

		if wall_run_dir.dot(velocity) < 0:
			wall_run_dir *= -1
			
		return;
	
	if is_wall_running():
		print("stopped_wall_running")
		stop_wall_running();
	
func is_wall_running() -> bool:
	return movement_state == MOVEMENT_STATES.wallrun;
	
func stop_wall_running(jumping : bool = false) -> void:
	movement_state = MOVEMENT_STATES.crouch if is_crouched else MOVEMENT_STATES.normal;
	wall_run_normal = Vector3.ZERO;
	wall_run_dir = Vector3.ZERO; 
	static_crouch_y = false;
	
	if jumping : no_decell = 0.2;
	

func air_movement_wallrun(delta : float) -> void:
	
	coyote_time_info = [wall_run_normal, coyote_time]
	
	check_wall_run(delta);
	
#endregion
	
#region chains


var chain_active: bool = false
var chain_enemy: Node3D = null
var chain_radius: float = 0.0
var chain_thickness: float = 0.3

var chain_sources: Array = []
func add_chain_source(enemy: Node3D) -> void:
	if enemy not in chain_sources:
		chain_sources.append(enemy)

func remove_chain_source(enemy: Node3D) -> void:
	chain_sources.erase(enemy)

func get_active_chain() -> Dictionary:
	var best = null
	var best_dist = 0

	var player_pos = get_center_point().global_position;

	for enemy in chain_sources:
		if not enemy.chain_active:
			continue

		var dist = player_pos.distance_to(enemy.get_center_point().global_position)
		
		if dist >= enemy.current_radius - (0.15 if chain_active else 0.) and dist > best_dist:
			best = enemy
			best_dist = dist

	if best:
		
		var normal = (player_pos - best.get_center_point().global_position).normalized()
		return {
			"active": true,
			"normal": normal,
			"enemy": best
		}

	return {"active": false}


var smoothed_wall_normal := Vector3.ZERO;
func apply_chain_constraint(delta: float):
	var chain = get_active_chain()

	if not chain.active:
		chain_active = false;
		return

	var enemy = chain.enemy
	var player_center = get_center_point().global_position
	var enemy_center = enemy.get_center_point().global_position

	var dir = player_center - enemy_center
	var length = dir.length()
	var normal = dir / length

	# Kill outward velocity
	var outward_speed = velocity.dot(normal)
	var wish_dot = wish_dir.dot(normal);
	var og_velocity = velocity;
	
	if outward_speed >= 0:
		velocity -= normal * outward_speed
	
		var overflow = length - enemy.current_radius
		if wish_dot >= 0 and overflow > 0:

			# Clamp to sphere surface (from center to center)
			var target_center = enemy_center + normal * enemy.current_radius

			# Convert center → actual player position
			var offset = player_center - global_position
			global_position = target_center - offset
			# Use new version — pass position and sphere center
			
			velocity = MovementUtils.sphere_redirect_velocity(og_velocity, target_center, enemy_center)
			print("%s %s" % [og_velocity.length(), velocity.length()])

			wall_run_normal = -normal;
			wall_run_dir = velocity.normalized();
			
			if is_crouched:
				change_crouch_dir(velocity.normalized())
				static_crouch_y = true

	chain_active = true;

#endregion
	
func air_movement_normal(delta) -> void:
	
	# Handle slope collisions during air dash
	if dash_state == DashState.AIR_DASH and is_on_wall():
		var wall_normal = get_wall_normal()
		var is_slope = wall_normal.y < 0.98 and wall_normal.y > 0.1
		if is_slope:
			var slope_angle = acos(wall_normal.dot(Vector3.UP))
			var slope_steepness = slope_angle / (PI / 2)
			var horizontal_speed = Vector3(velocity.x, 0, velocity.z).length()
			var launch_multiplier = lerp(1.6, 0.6, slope_steepness)
			velocity.y = horizontal_speed * launch_multiplier * sin(slope_angle)
			var speed_retention = lerp(1.0, 0.7, slope_steepness)
			velocity.x *= speed_retention
			velocity.z *= speed_retention
			dash_state = DashState.COOLDOWN
			motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
			return
	
	# Skip air control and let the dash carry the player
	if dash_state == DashState.AIR_DASH:
		return
	
	var cur_speed_in_wish_dir = self.velocity.dot(wish_dir)
	
	var capped_speed = min((air_move_speed * wish_dir).length(), air_cap)
	if no_decell > 0.0 and wish_dir.dot(velocity) < 0 : return;
	
	var add_speed_till_cap = capped_speed - cur_speed_in_wish_dir;
	if add_speed_till_cap > 0:
		var accel_speed = air_acccel * air_move_speed * delta
		accel_speed = min(accel_speed, add_speed_till_cap)
		self.velocity += accel_speed * wish_dir;
	
	check_wall_run(delta);

func air_movement_crouch(delta) -> void:
	
	slide_player();
	check_wall_run(delta);

func _handle_air_physics(delta: float) -> void:
	
	no_decell = maxf(no_decell - delta, 0.0);
	
	# Restore grounded motion mode once air dash ends
	if dash_state != DashState.AIR_DASH:
		motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	
	match movement_state:
		
		MOVEMENT_STATES.normal:
			air_movement_normal(delta);
			
		MOVEMENT_STATES.crouch:
			air_movement_crouch(delta);
			
		MOVEMENT_STATES.wallrun:
			air_movement_wallrun(delta);
			
	if !static_crouch_y : self.velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta * (1 - int(is_wall_running() and velocity.y < 0) * 0.9) * int(dash_state != DashState.AIR_DASH);
	
	
	pass

#endregion

#region Ground Physics

func ground_movement_normal(delta: float) -> void:
	
	# Don't accelerate or apply friction during an active ground dash
	if dash_state == DashState.GROUND_DASH:
		return
	
	var cur_speed_in_wish_dir = self.velocity.dot(wish_dir)
	var add_speed_till_cap = get_move_speed() - cur_speed_in_wish_dir
	
	if add_speed_till_cap > 0:
		var accel_speed = ground_accel * delta * get_move_speed()
		accel_speed = min(accel_speed, add_speed_till_cap)
		self.velocity += accel_speed * wish_dir
		
	MovementUtils.apply_ground_friction(self, delta)
	
	camera_component._headbob_effect(delta, self.velocity.length());

func ground_movement_crouch(delta) -> void:

	
	slide_player();
	slide_knockback();
	pass;

func _handle_ground_physics(delta: float) -> void:
	
	if is_wall_running() : movement_state = MOVEMENT_STATES.normal;
	no_decell = 0.0;
	
	
	match movement_state:
		MOVEMENT_STATES.normal:
			ground_movement_normal(delta)
			
		MOVEMENT_STATES.crouch:
			ground_movement_crouch(delta)
			
	pass

#endregion

#region Dash System

func _handle_dash_input() -> void:
	if not Input.is_action_just_pressed("sprint"):
		return
	if not dash_ready:
		return
	if MovementUtils.really_on_floor(self):
		_execute_ground_dash()
	else:
		_execute_air_dash()

func _execute_ground_dash() -> void:
	var dash_direction = _get_dash_direction()
	var floor_info = _get_floor_slope_info()
	var slope_ahead_info = _raycast_slope_ahead(dash_direction)

	var is_on_slope = floor_info.is_slope
	var slope_detected = slope_ahead_info.has_slope

	var is_on_steep_slope = false
	var steep_slope_normal = Vector3.UP
	if is_on_wall():
		var wall_normal = get_wall_normal()
		if wall_normal.y > 0.1 and wall_normal.y < 0.98:
			is_on_steep_slope = true
			steep_slope_normal = wall_normal
			is_on_slope = true
			floor_info.normal = wall_normal

	velocity = dash_direction * dash_speed

	if is_on_slope or slope_detected or is_on_steep_slope:
		last_dash_type = DashType.GROUND_SLOPE

		var launch_normal = steep_slope_normal if is_on_steep_slope else (slope_ahead_info.normal if slope_detected else floor_info.normal)
		var slope_angle = acos(launch_normal.dot(Vector3.UP))
		var slope_steepness = slope_angle / (PI / 2)

		var speed_reduction = lerp(1.0, 0.2, slope_steepness)
		velocity.x *= speed_reduction
		velocity.z *= speed_reduction

		var launch_multiplier = lerp(1.6, 0.5, slope_steepness)
		var base_upward_force = dash_speed * launch_multiplier
		velocity.y = base_upward_force * sin(slope_angle)

		var horizontal_boost = 1.2
		velocity.x *= horizontal_boost
		velocity.z *= horizontal_boost

		_was_on_floor_last_frame = false
		motion_mode = CharacterBody3D.MOTION_MODE_FLOATING

		dash_state = DashState.COOLDOWN
		dash_ready = false
		dash_time_remaining = 0.0
		dash_jump_consumed = true
	else:
		last_dash_type = DashType.GROUND_FLAT

		velocity.y = 0.2
		motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED

		dash_state = DashState.GROUND_DASH
		dash_ready = false
		dash_time_remaining = dash_ground_duration
		dash_start_time = 0.0
		dash_jump_consumed = false

func _execute_air_dash() -> void:
	if air_dash_count >= max_air_dashes:
		return

	last_dash_type = DashType.AIR

	var dash_direction = _get_dash_direction()

	velocity = dash_direction * dash_speed
	velocity.y = 0.0

	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING

	dash_state = DashState.AIR_DASH
	dash_ready = false
	dash_time_remaining = dash_air_duration
	dash_start_time = 0.0
	air_dash_count += 1

func _execute_dash_jump() -> void:
	dash_jump_consumed = true
	velocity.y = dash_jump_velocity
	dash_jump_requested = false
	dash_state = DashState.COOLDOWN
	dash_time_remaining = 0.0

func _get_dash_direction() -> Vector3:
	if wish_dir.length() > 0.01:
		return wish_dir.normalized()
	else:
		var cam_forward = -LevelController.player_camera.global_transform.basis.z
		return Vector3(cam_forward.x, 0.0, cam_forward.z).normalized()

func _get_floor_slope_info() -> Dictionary:
	var floor_normal = get_floor_normal()
	return {
		"is_slope": floor_normal.y < 0.98,
		"normal": floor_normal
	}

func _raycast_slope_ahead(direction: Vector3) -> Dictionary:
	var horizontal_dir = Vector3(direction.x, 0.0, direction.z).normalized()
	var space_state = get_world_3d().direct_space_state

	var offsets = [Vector3.ZERO, Vector3(0, 0.5, 0), Vector3(0, -0.5, 0)]
	for offset in offsets:
		var start_pos = global_position + offset
		var end_pos = start_pos + horizontal_dir * raycast_distance + Vector3(0, -0.5, 0)
		var query = PhysicsRayQueryParameters3D.create(start_pos, end_pos)
		var result = space_state.intersect_ray(query)
		if result:
			var normal = result.normal
			if normal.y < 0.98 and normal.y > 0.1:
				return {"has_slope": true, "normal": normal}

	return {"has_slope": false, "normal": Vector3.UP}

func _update_dash_state(delta: float) -> void:
	match dash_state:
		DashState.GROUND_DASH, DashState.AIR_DASH:
			dash_time_remaining -= delta
			dash_start_time += delta
			if dash_time_remaining <= 0.0:
				dash_state = DashState.COOLDOWN
				_reset_dash_flags()

func _handle_dash_jump_input() -> void:
	if not Input.is_action_just_pressed("jump"):
		return
	if dash_state == DashState.GROUND_DASH and not dash_jump_consumed:
		if dash_time_remaining > 0.0:
			dash_jump_requested = true

func _handle_dash_landing() -> void:
	var now_on_floor = MovementUtils.really_on_floor(self)
	var now_on_wall = is_on_wall()

	if now_on_floor and not _was_on_floor_last_frame:
		if dash_state == DashState.COOLDOWN or dash_state == DashState.AIR_DASH or (dash_state == DashState.READY_TO_DASH and not dash_ready):
			_recharge_dash()
			motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
			return

	if now_on_floor and dash_state == DashState.COOLDOWN:
		_recharge_dash()
		motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
		return

	if now_on_wall and not _was_on_floor_last_frame:
		var wall_normal = get_wall_normal()
		if wall_normal.y > 0.1 and wall_normal.y < 0.98:
			if dash_state == DashState.COOLDOWN or (dash_state == DashState.READY_TO_DASH and not dash_ready):
				_recharge_dash()
				motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
				return

	if now_on_wall and dash_state == DashState.COOLDOWN:
		var wall_normal = get_wall_normal()
		if wall_normal.y > 0.1 and wall_normal.y < 0.98:
			_recharge_dash()
			motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
			return

func _reset_dash_flags() -> void:
	dash_jump_requested = false
	dash_jump_consumed = false

func _recharge_dash() -> void:
	dash_ready = true
	air_dash_count = 0
	dash_state = DashState.READY_TO_DASH
	_reset_dash_flags()
	last_dash_type = DashType.NONE

#endregion

func _physics_process(delta: float) -> void:
	
	motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	
	var on_floor = MovementUtils.really_on_floor(self);
	if on_floor: _last_frame_was_on_floor = Engine.get_physics_frames()
	
	camera_component.set_camera_tilt(0.);
	InputController.update(delta);
	
	
	var input_dir = InputController.input_dir;
	wish_dir = self.global_transform.basis * Vector3(input_dir.x, 0., input_dir.y)
	
	_handle_dash_input()
	_handle_dash_jump_input()
	_handle_dash_landing()
	_update_dash_state(delta)
	
	_handle_crouch(delta);
	
	if on_floor:
		coyote_time_info = [Vector3.ZERO, coyote_time]
		_handle_ground_physics(delta)
	else:
		_handle_air_physics(delta)
	
	
	
	#region coyoteTime
	if coyote_time_info[COYOTE_TIME_INDEXES.TimeLeft] > 0. : 
		
		if player_jump(coyote_time_info[COYOTE_TIME_INDEXES.WallNormal]):
			coyote_time_info[COYOTE_TIME_INDEXES.TimeLeft] = 0.;
			
	coyote_time_info[COYOTE_TIME_INDEXES.TimeLeft] = max(
		coyote_time_info[COYOTE_TIME_INDEXES.TimeLeft] - delta, 
		0)
	#endregion
	
	if dash_jump_requested and not dash_jump_consumed:
		_execute_dash_jump()
	
	#Commented out the player because I'm afraid it might mess their trajectory or something and make them miss kicks.
	#Should be fine to leave out.
	#MovementUtils.soft_collide(self, %PersonalSpaceArea, delta)
	
	var original_velocity = velocity;
	
	apply_chain_constraint(delta);
	
	if not MovementUtils._snap_up_stairs_check(self, %StairsAheadRayCast3D, delta, camera_component):
	
		move_and_slide();
		MovementUtils._snap_down_to_stairs_check(self, %StairsBelowRayCast3D, is_crouched, camera_component);
	
	wall_redirect(original_velocity);
	
	floor_redirect(original_velocity);
		
	if is_wall_running():
		var tilt_dir = -wall_run_normal.dot(global_transform.basis.x)
		camera_component.set_camera_tilt(deg_to_rad(CAMERA_WALLRUN_TILT_ANGLE) * tilt_dir)
	
	camera_component.update(delta);
	camera_component._slide_camera_smooth_back_to_origin(delta, self.velocity.length(), get_move_speed())

	#Clamp player speed
	velocity = velocity.clamp(Vector3(-max_spd, -max_spd, -max_spd), Vector3(max_spd, max_spd, max_spd))
	
	_was_on_floor_last_frame = MovementUtils.really_on_floor(self)
	
	pass

func wall_redirect(original_velocity: Vector3) -> void:
	#Redirect direction when hitting a wall at an angle
	if is_on_wall():
		
		var wall_normal = get_wall_normal()

		if MovementUtils.get_horizontal_vector(velocity).length() < MovementUtils.get_horizontal_vector(original_velocity).length():
		
			var redirected = MovementUtils.redirect_velocity(original_velocity, wall_normal);
			
			if redirected != original_velocity:
				
				if is_crouched:
					temp_crouch_dir = MovementUtils.get_horizontal_vector(velocity).normalized();
				else:
					velocity = redirected;
					
		elif is_crouched:
			force_uncrouch()
	else:
		temp_crouch_dir = Vector3.ZERO

func floor_redirect(original_velocity : Vector3) -> void:
	#Redirect speed when hitting the floor at an angle while crouching
	if is_crouched and MovementUtils.really_on_floor(self):
		
		if velocity.length() < original_velocity.length():
			velocity = MovementUtils.redirect_velocity(original_velocity, get_floor_normal()) * (1. if crouch_dir.y == 0 else 0.4);
			
			if crouch_dir.y < 0:
			
				var spd = velocity.length();
				var new_dir = MovementUtils.redirect_velocity(crouch_dir, Vector3.UP, 0.3 / (spd / 10. if spd > 15 else 1.));
				
				if new_dir == crouch_dir : 
					force_uncrouch()
				else:	
					crouch_dir = new_dir;
					
				static_crouch_y = false;
			
		

func slide_knockback() -> void:
	
	for body in personal_space_area.get_overlapping_bodies():
		
		if !body.is_in_group("dynamic") or !MovementUtils.really_on_floor(body): continue;
		if body.knockback_multiplier == 0.0 : continue;
		
		body.velocity = Vector3.ZERO;
		
		var pos = global_position - velocity;
		var dir = MovementUtils.get_horizontal_vector(pos.direction_to(body.global_position)).normalized();
		var strength = MovementUtils.get_horizontal_vector(velocity).length() * 1.3;
		
		MovementUtils.apply_knockback(body, dir, strength, 4.);
		
		LevelController.add_score(
			LevelController.HIT_BY_PLAYER,
			10,
			LevelController.get_hit_score_arguments(false, LevelController.player.velocity.length())
			)
		
		body.blow_away();

func _process(delta: float) -> void:
	
	
	weapon_manager.update(delta)
	#rocket_launcher_component.update(delta)
	telekinesis_component.update(delta)
	
	health_component.set_resistance("speed_resistance", max(0.25, 1 - 0.25 * (velocity.length()/8.)))
	
	_handle_controller_look_input(delta)

	if InputController.fire_primary():
		weapon_manager.fire_primary()

	if InputController.reload_primary():
		weapon_manager.reload_primary()
	
	#if InputController.fire_rocket():
		#rocket_launcher_component.launch_rocket()

	if InputController.do_kick():
		kick_module.kick();
	
	if InputController.launch_enemy():
		telekinesis_component.launch_enemy()
	
	var val = velocity.length() / Vector3(max_spd, max_spd, max_spd).length();
	camera_component.updateFOV(delta, val * 2)
	pass
