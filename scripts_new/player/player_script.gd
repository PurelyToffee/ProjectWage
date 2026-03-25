class_name PlayerClass extends CharacterBody3D

@onready var camera_component: CameraComponent = $CameraComponent
@onready var rocket_launcher_component: RocketLauncherComponent = $RocketLauncherComponent
@onready var kick_module: KickModule = $KickModule
@onready var health_component: HealthComponent = $HealthComponent # useless for now
@onready var weapon_manager: WeaponManager = $WeaponManager
@onready var telekinesis_component: TekelinesisComponent = $TelekinesisComponent


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

@onready var _original_capsule_height = $CollisionShape3D.shape.height;
const CROUCH_TRANSLATE = 0.7;
const CROUCH_JUMP_ADD = CROUCH_TRANSLATE * 0.9;
const CROUCH_MIN_SPEED = 10;
var is_crouched := false;
var crouch_wish := false;

var was_crouched_last_frame := false;

var wall_running := false;

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
	crouch
}

var movement_state : int = MOVEMENT_STATES.normal;


var wish_dir := Vector3.ZERO;
var crouch_dir := Vector3.ZERO;

func _ready() -> void:
	
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
	
	health_component.setup(100, false) # useless for now
	health_component.connect("died", on_death)
	
	var dual = LevelController.DualMacTen.new();
	weapon_manager.add_weapon(dual);
	
	pass


func on_death() -> void:
	LevelController.player_died();

func force_uncrouch() -> void:
	crouch_wish = false;

func change_crouch_dir(dir : Vector3) -> void:
	crouch_dir = MovementUtils.get_horizontal_vector(dir).normalized();

func _handle_crouch(delta) -> void:
	
	#if input_component.just_crouched() : crouch_wish = !crouch_wish
	# if is_crouched != crouch_wish:
	if InputController.is_crouching():
		if !is_crouched:
			is_crouched = true
			change_crouch_dir(MovementUtils.get_look_direction_vector(%Camera3D))
			movement_state = MOVEMENT_STATES.crouch
	elif is_crouched and not self.test_move(self.transform, Vector3(0, CROUCH_TRANSLATE, 0)):
		is_crouched = false;
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

	was_crouched_last_frame = is_crouched;

func slide_player() -> void:
	
	var horizontal_velocity = MovementUtils.get_horizontal_vector(self.velocity);
	var spd = max(horizontal_velocity.length(), CROUCH_MIN_SPEED);
	
	self.velocity.x = spd * crouch_dir.x;
	self.velocity.z = spd * crouch_dir.z;


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
			
			if on_wall:
				self.velocity += wall_normal * jump_velocity;
			
			self.velocity.y += jump_velocity * (1 - 0.4 * int(on_wall));
			
			if is_crouched:
				
				if on_wall:
					change_crouch_dir(self.velocity.normalized());
				else:
					change_crouch_dir(MovementUtils.get_look_direction_vector(self));
					
				slide_player();
			
			return true;
	
	return false;

#endregion

#region Camera Control

func _unhandled_input(event: InputEvent) -> void:
	
	InputController.capture_mouse(event);	
		
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			
			rotate_y(-event.relative.x * look_sensitivity)
			camera_component.rotate_x(-event.relative.y * look_sensitivity, deg_to_rad(-90), deg_to_rad(90))
		

func _handle_controller_look_input(delta : float):
	
	_cur_controller_look = InputController.controller_target_look;
	
	rotate_y(-_cur_controller_look.x * controller_look_sensitivity)
	camera_component.rotate_x(_cur_controller_look.y * controller_look_sensitivity, deg_to_rad(-90), deg_to_rad(90))

#endregion

#region Air Physics
		
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
	
func wall_run(delta : float) -> void:
	
	if is_on_wall():
		
		var wall_normal = get_wall_normal();
		
		if can_wall_run(wall_normal):
			
			if self.velocity.y < 0: wall_running = true
			
			coyote_time_info = [wall_normal, coyote_time]
			
			var tilt_dir = -sign(wall_normal.dot(global_transform.basis.x))
			camera_component.set_camera_tilt(deg_to_rad(CAMERA_WALLRUN_TILT_ANGLE) * tilt_dir)
			
		if MovementUtils.is_surface_too_steep(self, wall_normal):
			self.motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
		
		MovementUtils.clip_velocity(self, wall_normal, 1, delta)
	
func air_movement_normal(delta) -> void:
	
	wall_running = false;
	var cur_speed_in_wish_dir = self.velocity.dot(wish_dir)
	
	var capped_speed = min((air_move_speed * wish_dir).length(), air_cap)
	
	var add_speed_till_cap = capped_speed - cur_speed_in_wish_dir;
	if add_speed_till_cap > 0:
		var accel_speed = air_acccel * air_move_speed * delta
		accel_speed = min(accel_speed, add_speed_till_cap)
		self.velocity += accel_speed * wish_dir;
	
	wall_run(delta);

func air_movement_crouch(delta) -> void:
	
	slide_player();
	wall_run(delta);

func _handle_air_physics(delta: float) -> void:
	
	wall_running = false;
	
	match movement_state:
		
		MOVEMENT_STATES.normal:
			air_movement_normal(delta);
			
		MOVEMENT_STATES.crouch:
			air_movement_crouch(delta);
	
	self.velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta * (1 - int(wall_running) * 0.8);
	
	pass

#endregion

#region Ground Physics

func ground_movement_normal(delta: float) -> void:
	
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
	pass;

func _handle_ground_physics(delta: float) -> void:
	
	match movement_state:
		MOVEMENT_STATES.normal:
			ground_movement_normal(delta)
			
		MOVEMENT_STATES.crouch:
			ground_movement_crouch(delta)
			
	pass

#endregion

func _physics_process(delta: float) -> void:
	
	motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	
	var on_floor = MovementUtils.really_on_floor(self);
	if on_floor: _last_frame_was_on_floor = Engine.get_physics_frames()
	
	camera_component.set_camera_tilt(0.);
	InputController.update(delta);
	
	
	var input_dir = InputController.input_dir;
	wish_dir = self.global_transform.basis * Vector3(input_dir.x, 0., input_dir.y)
	
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
	
	#Commented out the player because I'm afraid it might mess their trajectory or something and make them miss kicks.
	#Should be fine to leave out.
	#MovementUtils.soft_collide(self, %PersonalSpaceArea, delta)
	
	if not MovementUtils._snap_up_stairs_check(self, %StairsAheadRayCast3D, delta, camera_component):
	
		move_and_slide();
		MovementUtils._snap_down_to_stairs_check(self, %StairsBelowRayCast3D, is_crouched, camera_component);
	
	if is_on_wall() and MovementUtils.get_horizontal_vector(velocity).length() < 3. : force_uncrouch();
	
	camera_component.update(delta);
	camera_component._slide_camera_smooth_back_to_origin(delta, self.velocity.length(), get_move_speed())
	pass

func _process(delta: float) -> void:
	
	
	weapon_manager.update(delta)
	rocket_launcher_component.update(delta)
	telekinesis_component.update(delta)

	_handle_controller_look_input(delta)

	if InputController.fire_primary():
		weapon_manager.fire_primary()

	if InputController.reload_primary():
		weapon_manager.reload_primary()
	
	if InputController.fire_rocket():
		rocket_launcher_component.launch_rocket()

	if InputController.do_kick():
		kick_module.kick();
	
	if InputController.launch_enemy():
		telekinesis_component.launch_enemy()
	
	pass
