extends CharacterBody3D

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

const HEADBOB_MOVE_AMMOUNT := 0.06;
const HEADBOB_FREQUENCY := 2.4;
var headbob_time := 0.;

var wish_dir := Vector3.ZERO;

var camera_tilt_target := 0.;


func get_move_speed() -> float:
	return sprint_speed if Input.is_action_pressed("sprint") else walk_speed

func _ready() -> void:
	
	for child in %WorldModel.find_children("*", "VisualInstance3D"):
		child.set_layer_mask_value(1, false);
		child.set_layer_mask_value(2, true);
	
	pass
	
func _unhandled_input(event: InputEvent) -> void:
	
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
		
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			rotate_y(-event.relative.x * look_sensitivity)
			%Camera3D.rotate_x(-event.relative.y * look_sensitivity)
			%Camera3D.rotation.x = clamp(%Camera3D.rotation.x, deg_to_rad(-90), deg_to_rad(90))
		

func is_surface_too_steep(normal : Vector3) -> bool:
	var max_slope_ang_dot := Vector3(0, 1, 0).rotated(Vector3(1.0, 0, 0), self.floor_max_angle).dot(Vector3(0, 1, 0))
	
	return normal.dot(Vector3(0,1,0)) < max_slope_ang_dot;

func set_camera_tilt(target : float = 0.) -> void:
	camera_tilt_target = target;

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
		var wall_dot_velocity = wall_normal.dot(self.velocity);
		
		if abs(wall_dot_velocity) < 0.8 and (wall_dot_velocity <= 0):
			
			if self.velocity.y < 0: wall_running = 1
			
			player_jump(wall_normal);
			var tilt_dir = -sign(wall_normal.dot(global_transform.basis.x))
			set_camera_tilt(deg_to_rad(20) * tilt_dir)
			
		if is_surface_too_steep(wall_normal):
			self.motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
		else:
			self.motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
		
		clip_velocity(wall_normal, 1, delta)
	
	self.velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta * (1 - wall_running * 0.8)
	
	pass

func clip_velocity(normal: Vector3, overbounce : float, delta : float) -> void:
	
	var backoff := self.velocity.dot(normal) * overbounce
	
	if backoff >= 0: return
	
	var change := normal * backoff
	self.velocity -= change
	
	var adjust := self.velocity.dot(normal)
	if adjust < 0.0:
		self.velocity -= normal * adjust
		

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
	
	_headbob_effect(delta);
	pass

var _cur_controller_look = Vector2()
func _handle_controller_look_input(delta : float):
	var target_look = Input.get_vector("look_left", "look_right", "look_down", "look_up")
	
	_cur_controller_look = target_look;
	
	rotate_y(-_cur_controller_look.x * controller_look_sensitivity)
	%Camera3D.rotate_x(_cur_controller_look.y * controller_look_sensitivity)
	%Camera3D.rotation.x = clamp(%Camera3D.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func player_jump(wall_normal : Vector3 = Vector3.ZERO) -> void:
		
	var on_wall = wall_normal != Vector3.ZERO;
	
	if Input.is_action_just_pressed("jump") or (!on_wall and auto_bhop and Input.is_action_pressed("jump")):
			
			if on_wall:
				self.velocity += wall_normal * jump_velocity;
			
			self.velocity.y = jump_velocity

func _physics_process(delta: float) -> void:
	
	var input_dir = Input.get_vector("left", "right", "up", "down").normalized()
	wish_dir = self.global_transform.basis * Vector3(input_dir.x, 0., input_dir.y)
	
	set_camera_tilt(0.);
	
	if is_on_floor():
		
		player_jump();
			
		_handle_ground_physics(delta)
	else:
		_handle_air_physics(delta)
	
	move_and_slide()
	
	%Camera3D.rotation.z = lerp(%Camera3D.rotation.z, camera_tilt_target, 10 * delta);
	
	pass
	
func _headbob_effect(delta: float):
	headbob_time += delta * self.velocity.length();
	%Camera3D.transform.origin = Vector3(
		cos(headbob_time * HEADBOB_FREQUENCY * 0.5) * HEADBOB_MOVE_AMMOUNT,
		sin(headbob_time * HEADBOB_FREQUENCY) * HEADBOB_MOVE_AMMOUNT,
		0
	)
	
	pass
	
func _process(delta: float) -> void:
	
	_handle_controller_look_input(delta)
	
	pass
