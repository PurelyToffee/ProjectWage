class_name PlayerClass extends DynamicCharacterBody

@onready var camera_component: CameraComponent = $CameraComponent
#@onready var rocket_launcher_component: RocketLauncherComponent = $RocketLauncherComponent
@onready var kick_module: KickModule = $KickModule
@onready var weapon_manager: WeaponManager = $WeaponManager
@onready var telekinesis_component: TekelinesisComponent = $TelekinesisComponent
@onready var dash_component: DashComponent = $DashComponent
@onready var personal_space_area: Area3D = %PersonalSpaceArea
@onready var personal_space_shape: CollisionShape3D = %PersonalSpaceShape
@onready var original_personal_space_height = personal_space_shape.shape.height;


@export var look_sensitivity : float = 0.004;
@export var controller_look_sensitivity : float = 0.05;
@export var ground_accel : float = 14.0;
@export var ground_deccel : float = 10.0;
@export var ground_friction : float = 6.0;
var no_decell : float = 0.0;

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

@onready var _original_capsule_height = $CollisionShape3D.shape.height;
const CROUCH_TRANSLATE = 0.7;
const CROUCH_JUMP_ADD = CROUCH_TRANSLATE * 0.9;
const CROUCH_MIN_SPEED = 10;
var is_crouched := false;
var crouch_wish := false;
var crouchable := true;
var static_crouch_y := false;

var was_crouched_last_frame := false;

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
	wallrun,
	dash
}

var movement_state : int = MOVEMENT_STATES.normal;


var wish_dir := Vector3.ZERO;
var crouch_dir := Vector3.ZERO;
var temp_crouch_dir := Vector3.ZERO;

func _ready() -> void:
	
	print("ground_accel at ready: ", ground_accel);
	health_component = $HealthComponent;
	
	dash_component.holder = self;
	dash_component.connect("stop_dashing", stop_dashing)
	
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

			wall_run_normal = -normal;
			wall_run_dir = velocity.normalized();
			
			if is_crouched:
				change_crouch_dir(velocity.normalized())
				static_crouch_y = true

	chain_active = true;

#endregion
	
func air_movement_normal(delta) -> void:
	
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
	
	match movement_state:
		
		MOVEMENT_STATES.normal:
			air_movement_normal(delta);
			
		MOVEMENT_STATES.crouch:
			air_movement_crouch(delta);
			
		MOVEMENT_STATES.wallrun:
			air_movement_wallrun(delta);
			
	if !static_crouch_y : 
		
		var wall_running_multiplier = (1 - int(is_wall_running() and velocity.y < 0) * 0.9)
		var dash_multiplier = 1 - int(is_dashing()) * 0.9;
		
		var final_multiplier = dash_multiplier * wall_running_multiplier;
		
		self.velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta * final_multiplier;
	
	
	pass

#endregion

#region Ground Physics

func ground_movement_normal(delta: float) -> void:
	
	if no_decell > 0.0 and wish_dir.dot(velocity) < 0 : return;
	
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

func _physics_process(delta: float) -> void:
	
	motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	
	var on_floor = MovementUtils.really_on_floor(self);
	if on_floor: _last_frame_was_on_floor = Engine.get_physics_frames()
	
	camera_component.set_camera_tilt(0.);
	InputController.update(delta);
	
	
	var input_dir = InputController.input_dir;
	wish_dir = self.global_transform.basis * Vector3(input_dir.x, 0., input_dir.y)

	_handle_crouch(delta);
	

	if wish_dir.dot(velocity) <= 0. and wish_dir != Vector3.ZERO:
		dash_component.change_dash_dir(wish_dir);
	
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
	
	var original_velocity = velocity;
	
	apply_chain_constraint(delta);
	
	if not MovementUtils._snap_up_stairs_check(self, %StairsAheadRayCast3D, delta, camera_component):
	
		move_and_slide();
		MovementUtils._snap_down_to_stairs_check(self, %StairsBelowRayCast3D, is_crouched, camera_component);
	
	if is_crouched : MovementUtils.slope_speedup(self)
	
	wall_redirect(original_velocity);
	
	floor_redirect(original_velocity);
		
	if is_wall_running():
		var tilt_dir = -wall_run_normal.dot(global_transform.basis.x)
		camera_component.set_camera_tilt(deg_to_rad(CAMERA_WALLRUN_TILT_ANGLE) * tilt_dir)
	
	camera_component.update(delta);
	camera_component._slide_camera_smooth_back_to_origin(delta, self.velocity.length(), get_move_speed())

	#Clamp player speed
	velocity = velocity.clamp(Vector3(-max_spd, -max_spd, -max_spd), Vector3(max_spd, max_spd, max_spd))
	
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

func is_dashing() -> bool:
	return movement_state == MOVEMENT_STATES.dash;

func stop_dashing() -> void:
	if !is_dashing() : return;
	
	if is_crouched :
		movement_state = MOVEMENT_STATES.crouch;
	else:
		movement_state = MOVEMENT_STATES.normal;

func _process(delta: float) -> void:
	
	
	weapon_manager.update(delta)
	#rocket_launcher_component.update(delta)
	telekinesis_component.update(delta)
	
	_handle_controller_look_input(delta)

	if InputController.fire_primary():
		weapon_manager.fire_primary()

	if InputController.reload_primary():
		weapon_manager.reload_primary()
	
	#if InputController.fire_rocket():
		#rocket_launcher_component.launch_rocket()

	if InputController.dash() and !is_dashing():
		
		var dash_dir = wish_dir if wish_dir != Vector3.ZERO else MovementUtils.get_horizontal_vector(MovementUtils.get_look_direction_vector(LevelController.player_camera))
		dash_component.dash(dash_dir);
		movement_state = MOVEMENT_STATES.dash;
		
		if is_crouched : change_crouch_dir(dash_dir);
		
		InputController.reset_dash_buffer();

	if InputController.do_kick():
		kick_module.kick();
	
	if InputController.launch_enemy():
		telekinesis_component.launch_enemy()
	
	var val = velocity.length() / Vector3(max_spd, max_spd, max_spd).length();
	camera_component.updateFOV(delta, val * 2)
	
	health_component.set_resistance("speed_resistance", max(0.25, 1 - 0.25 * (velocity.length()/12.)))
	
	pass
