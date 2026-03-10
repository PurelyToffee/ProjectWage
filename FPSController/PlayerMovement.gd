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

@export var coyote_time := 6.;
@export var coyote_time_info := [Vector3.ZERO, 0.];

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
	
	pass


#region helpers

func get_move_speed() -> float:
	return sprint_speed if Input.is_action_pressed("sprint") else walk_speed

func is_surface_too_steep(normal : Vector3) -> bool:
	var max_slope_ang_dot := Vector3(0, 1, 0).rotated(Vector3(1.0, 0, 0), self.floor_max_angle).dot(Vector3(0, 1, 0))
	
	return normal.dot(Vector3(0,1,0)) < max_slope_ang_dot;

#endregion

#region Movement Features

func player_jump(wall_normal : Vector3 = Vector3.ZERO) -> bool:
		
	var on_wall = wall_normal != Vector3.ZERO;
	
	if input_component.jump_pressed() or (!on_wall and auto_bhop and Input.is_action_pressed("jump")):
			
			input_component.jump_buffer = 0.;
			
			if on_wall:
				self.velocity += wall_normal * jump_velocity;
			
			self.velocity.y = jump_velocity
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
			
			coyote_time_info = [wall_normal, coyote_time]
			
			var tilt_dir = -sign(wall_normal.dot(global_transform.basis.x))
			camera_component.set_camera_tilt(deg_to_rad(20) * tilt_dir)
			
		if is_surface_too_steep(wall_normal):
			self.motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
		else:
			self.motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
		
		clip_velocity(wall_normal, 1, delta)
	
	self.velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta * (1 - wall_running * 0.8)
	
	pass

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
	
	input_component.update(delta);
	
	var input_dir = input_component.input_dir;
	wish_dir = self.global_transform.basis * Vector3(input_dir.x, 0., input_dir.y)
	
	camera_component.set_camera_tilt(0.);
	
	if is_on_floor():
		
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
		coyote_time_info[COYOTE_TIME_INDEXES.TimeLeft] - Global.deltaMultiplier)
	
	move_and_slide()
	
	camera_component.update(delta);
	
	pass

func _process(delta: float) -> void:

	_handle_controller_look_input(delta)

	pass
