class_name PlayerClass extends CustomCharacterBody

@onready var camera_component: CameraComponent = $CameraComponent
#@onready var rocket_launcher_component: RocketLauncherComponent = $RocketLauncherComponent
@onready var kick_module: KickModule = $KickModule
@onready var weapon_manager: WeaponManager = $WeaponManager
@onready var telekinesis_component: TekelinesisComponent = $TelekinesisComponent
@onready var dash_component: DashComponent = $DashComponent
@onready var personal_space_area: Area3D = %PersonalSpaceArea
@onready var personal_space_shape: CollisionShape3D = %PersonalSpaceShape
@onready var original_personal_space_height = personal_space_shape.shape.height;

var just_fired = false
var to_hit_floor = false
var footstep_timer: float = 0.0;
const STEP_INTERVAL_MIN: float = 0.25 # fastest pace
const STEP_INTERVAL_MAX: float = 0.45 # slowest pace

var slide_audio_timer: float = 0.0;
const SLIDE_AUDIO_INTERVAL: float = 0.337 # audio length

var stunned = false;
var stun_timer: SceneTreeTimer;
@export var stun_timeout: float = 0.8;

@export var starting_weapons : Array[LevelController.WEAPONS] = [LevelController.WEAPONS.DMacTen, LevelController.WEAPONS.GLauncher, LevelController.WEAPONS.Pistol];

@export var look_sensitivity : float = 0.002;
@export var controller_look_sensitivity : float = 0.05;
var no_decell : float = 0.0;
var wall_run_no_decell := 0.5;

@export var max_spd := 64.0;
var max_step_spd := 15;
@export var jump_velocity := 6.0;
var wall_jump_count := 0.;
@export var auto_bhop := true;
@export var walk_speed := 9.0;

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


var original_velocity = velocity;
var original_transform = global_transform;
var original_position = global_position;

func _ready() -> void:
	
	$CollisionShape3D.shape = $CollisionShape3D.shape.duplicate()

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
	# camera_component.shader_rect = %ColorRect; TODO: doesnt exist
	
	health_component.setup(100, false) # useless for now
	health_component.connect("died", on_death)
	
	for weapon_id in starting_weapons:
		weapon_manager.add_weapon_by_id(weapon_id)
	
	pass


func on_death() -> void:
	var death_event = FmodServer.create_event_instance_with_guid("{6ded9668-4415-4c5b-afa3-d49724eaa562}")
	death_event.set_3d_attributes(global_transform)
	death_event.start()
	death_event.release()
	LevelController.player_died();

#region crouch/slide

func force_uncrouch() -> void:
	crouch_wish = false;
	crouchable = false;

func change_crouch_dir(dir : Vector3) -> void:
	crouch_dir = dir.normalized();
	temp_crouch_dir = Vector3.ZERO;

func _handle_footsteps(delta: float):
	var speed = self.velocity.length()
	if speed < 0.1:
		footstep_timer = 0.0
		return
	
	# map speed to step interval
	var step_interval = lerp(STEP_INTERVAL_MAX, STEP_INTERVAL_MIN, speed / max_step_spd); #TODO: check this max_spd var
	footstep_timer += delta
	if footstep_timer >= step_interval:
		footstep_timer = 0.0
		$WalkingEmitter.play()
		
func _handle_sliding_audio(delta: float):
	slide_audio_timer += delta
	if slide_audio_timer >= SLIDE_AUDIO_INTERVAL:
		slide_audio_timer = 0.0
		$SlideEmitter.play()
		
func _handle_crouch(delta) -> void:
	#if input_component.just_crouched() : crouch_wish = !crouch_wish
	# if is_crouched != crouch_wish:
	
	if !LevelController.player_abilities["slide"] : return;
	
	var res = self.test_move(self.transform, Vector3(0, CROUCH_TRANSLATE * 1.2, 0));
	
	crouchable = crouchable or !InputController.is_crouching();
	
	if crouchable and InputController.is_crouching() and !is_stunned():
		var on_floor =  self.is_on_floor() || is_wall_running()
		if on_floor:
			_handle_sliding_audio(delta)	
		if !is_crouched:
			if on_floor:
				$SlideEmitter.play()
			else:
				$DashEmitter.play()
			slide_audio_timer = 0.0
			is_crouched = true
			var dir = MovementUtils.get_look_direction_vector(%Camera3D);
			if !MovementUtils.really_on_floor(self) and dir.dot(Vector3.DOWN) >= 0 : 
				change_crouch_dir(dir);
			else:
				change_crouch_dir(MovementUtils.get_horizontal_vector(dir));
			
			movement_state = MOVEMENT_STATES.crouch
			
	elif is_crouched and not res:
		#_handle_sliding_audio(delta)
		$SlideEmitter.stop()
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
	return walk_speed

#endregion

#region Movement Features

var jump_frame := 0;
const JUMP_LOCK_FRAMES = 1;
func player_jump(wall_normal : Vector3 = Vector3.ZERO) -> bool:
	
	#if no_decell > 0. and wall_normal : return false;
	
	var on_wall = wall_normal != Vector3.ZERO;
	var frame = Engine.get_physics_frames();
	if InputController.jump_pressed() or (!on_wall and auto_bhop and Input.is_action_pressed("jump")):

			#Some walls explicitly disallow wall jumps. Bail before consuming the jump buffer
			#so the player keeps their buffered jump for the moment they leave the wall.
			if on_wall and is_no_wall_jump_wall(wall_normal) : return false;

			$JumpEmitter.play()
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
				
				var res = KinematicCollision3D.new();
				if test_move(global_transform, jump_dir, res): #If in a corner, don't wall jump.
					return false;
	
				var tangent = wall_normal.cross(Vector3.UP).normalized();
				var max_angle = deg_to_rad(60.0) # your limit
				var angle = camera_dir.angle_to(wall_normal)

				if angle > max_angle:
					# Axis to rotate around (stay on wall plane)
					var axis = wall_normal.cross(jump_dir).normalized()

					# Clamp by rotating wall_normal toward camera_dir
					jump_dir = wall_normal.rotated(axis, max_angle).normalized()
				
				var horizontal_spd = MovementUtils.get_horizontal_vector(velocity).length();
				var res_spd = jump_dir * max(abs(horizontal_spd), jump_velocity * 1.5)
				
				
				self.velocity.x = res_spd.x;
				self.velocity.z = res_spd.z;
				if velocity.y < jump_velocity * 1.5:
					self.velocity += vertical_dir * jump_velocity / maxf(1., wall_jump_count);
					self.velocity.y = clampf(self.velocity.y, 0., jump_velocity);
				
				wall_jump_count += 1.;
	
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

#Probes toward the wall (opposite its normal) to identify the collider the player
#would jump off of, and returns true if it's flagged as a no-wall-jump wall.
func is_no_wall_jump_wall(wall_normal : Vector3) -> bool:
	if wall_normal == Vector3.ZERO : return false;
	var coll = KinematicCollision3D.new();
	if test_move(global_transform, -wall_normal * 0.3, coll):
		return coll.get_collider() is NoWallJumpWall;
	return false;

#endregion

#region Camera Control

var visual_yaw : float = 0.0

var _mouse_delta : Vector2 = Vector2.ZERO

# _unhandled_input - just accumulate, don't rotate:
func _unhandled_input(event: InputEvent) -> void:
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			_mouse_delta += event.relative
		

func _handle_controller_look_input(delta : float):
	
	_cur_controller_look = InputController.controller_target_look;
	
	rotate_y(-_cur_controller_look.x * controller_look_sensitivity)
	camera_component.rotate_x(_cur_controller_look.y * controller_look_sensitivity, deg_to_rad(-90), deg_to_rad(90))

#endregion

#region Air Physics
		
#region wall_run
	
var wall_run_normal := Vector3.ZERO;
var wall_run_dir := Vector3.ZERO;
var transferred_wall_run := false;

# Frames the wall run survives without finding a wall, so transitions between a
# chainer sphere and a real wall (or wall-to-wall) don't drop on a 1-frame gap.
const WALL_RUN_GRACE_FRAMES := 5
var wall_run_grace := 0

func can_wall_run(wall_normal: Vector3) -> bool:
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
			var collision_point = body_test_result.get_position()
			var local_hit_height = collision_point.y - global_position.y
			
			# If the hit is too low, it's probably a step
			if local_hit_height > 0.3:  # tune this threshold
				wall_normal = body_test_result.get_normal()
				valid_wall = true

	if valid_wall and !is_stunned():

		wall_run_grace = WALL_RUN_GRACE_FRAMES
		movement_state = MOVEMENT_STATES.wallrun
		wall_run_normal = wall_normal
		wall_run_dir = wall_run_normal.cross(Vector3.UP).normalized()
		if wall_run_dir.dot(velocity) < 0:
			wall_run_dir *= -1

		var val = clampf((wall_jump_count - 1) * 0.1, 0.0, 0.3) if velocity.y > 0 else 0.
		velocity.y *= 1. - val;
		return;

	if is_wall_running():
		# Don't drop the run the instant a single frame finds no wall — a sphere<->wall
		# transition can leave a 1-frame gap where neither surface registers.
		wall_run_grace -= 1
		if wall_run_grace <= 0:
			stop_wall_running();

# Called right after move_and_slide() so collision data is fresh

var wall_transfer_cooldown := 0
const WALL_TRANSFER_COOLDOWN_FRAMES = 10

func check_wall_transfer() -> void:
	if not is_wall_running():
		return
	
	#print("=== check_wall_transfer | slide_count: %d | wall_run_normal: %s ===" % [get_slide_collision_count(), wall_run_normal])
	
	for i in get_slide_collision_count():
		var col = get_slide_collision(i)
		var col_normal = col.get_normal()
		var dot = col_normal.dot(wall_run_normal)
		
		#print("  col[%d] normal: %s | dot with wall_run_normal: %.3f | y: %.3f" % [i, col_normal, dot, col_normal.y])
		
		# Skip floor/ceiling
		if abs(col_normal.y) > 0.7:
			#print("    -> SKIP (floor/ceiling)")
			continue
		
		# Skip the wall we're already on
		if dot > 0.9:
			#print("    -> SKIP (same wall)")
			continue
		
		# Valid corner angle (<=90° between the walls)
		if dot >= -0.1:
			var new_wall_dir = col_normal.cross(Vector3.UP).normalized()
			
			if new_wall_dir.dot(wall_run_normal) < 0:
				new_wall_dir *= -1  # flip to match travel direction

			var preserved_speed = MovementUtils.get_horizontal_vector(original_velocity).length()
			velocity.x = new_wall_dir.x * preserved_speed
			velocity.z = new_wall_dir.z * preserved_speed

			wall_run_normal = col_normal
			wall_run_dir = new_wall_dir
			transferred_wall_run = true
			#print("    -> TRANSFERRED to new wall: %s | res : %s  | speed: %.2f" % [col_normal, velocity, preserved_speed])
			return
		
		#print("    -> SKIP (dot too negative: %.3f, angle too wide)" % dot)

func is_wall_running() -> bool:
	return movement_state == MOVEMENT_STATES.wallrun;
	
func stop_wall_running(jumping : bool = false) -> void:
	movement_state = MOVEMENT_STATES.crouch if is_crouched else MOVEMENT_STATES.normal;
	wall_run_normal = Vector3.ZERO;
	wall_run_dir = Vector3.ZERO;
	transferred_wall_run = false;
	static_crouch_y = false;
	
	if jumping : no_decell = wall_run_no_decell;
	

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

# wish·outward below -this lets the player deliberately pull free toward the center.
const CHAIN_INWARD_BREAK := 0.3
# Horizontal speed under which a chained player counts as pinned against a wall.
const CHAIN_STUCK_SPEED := 2.0
# Seconds pinned against a wall by the chain before the player dies.
const CHAIN_STUCK_TIME := 0.5
# Seconds caught in the pull of 2+ chainers before the player dies.
const CHAIN_PINCER_TIME := 0.15
var chain_stuck_timer := 0.0
var chain_pincer_timer := 0.0

func add_chain_source(enemy: Node3D) -> void:
	if enemy not in chain_sources:
		chain_sources.append(enemy)
		$ChainedEmitter.play()

func remove_chain_source(enemy: Node3D) -> void:
	chain_sources.erase(enemy)

# How many active chains are currently constraining the player (player at/outside
# their radius, so each is pulling inward). 2+ means a lethal pincer.
func count_constraining_chains() -> int:
	var count := 0
	var player_pos = get_center_point().global_position
	for enemy in chain_sources:
		if not is_instance_valid(enemy) or not enemy.chain_active:
			continue
		var dist = player_pos.distance_to(enemy.get_center_point().global_position)
		if dist >= enemy.current_radius:
			count += 1
	return count

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

	if health_component and health_component.dead:
		return

	var chain = get_active_chain()

	if not chain.active:
		chain_active = false;
		chain_stuck_timer = 0.0;
		chain_pincer_timer = 0.0;
		return

	# Death: caught in the inward pull of two or more chainers at once.
	if count_constraining_chains() >= 2:
		chain_pincer_timer += delta
		if chain_pincer_timer >= CHAIN_PINCER_TIME:
			kill()
			return
	else:
		chain_pincer_timer = 0.0

	var enemy = chain.enemy
	var player_center = get_center_point().global_position
	var enemy_center = enemy.get_center_point().global_position

	var dir = player_center - enemy_center
	var length = dir.length()
	var normal = dir / length

	var og_velocity = velocity;
	var radial_speed = velocity.dot(normal)   # >0 moving outward, <0 inward
	var wish_dot = wish_dir.dot(normal);

	# Never let the player accelerate off the sphere.
	if radial_speed > 0:
		velocity -= normal * radial_speed

	var overflow = length - enemy.current_radius

	# Let the player break free by deliberately pulling toward the center.
	var escaping_inward = wish_dot < -CHAIN_INWARD_BREAK

	if overflow > 0 and not escaping_inward:
		# Re-project onto the sphere surface EVERY frame while outside the radius.
		# Tangential motion travels in straight chords (always landing outside a
		# curved surface) and current_radius keeps shrinking, so gating this on
		# input made the player steadily drift out of range. Always correcting it
		# keeps them pinned to the surface.
		var target_center = enemy_center + normal * enemy.current_radius
		var offset = player_center - global_position
		global_position = target_center - offset

		velocity = MovementUtils.sphere_redirect_velocity(og_velocity, target_center, enemy_center)

		wall_run_normal = -normal;
		wall_run_dir = velocity.normalized();

		if is_crouched:
			change_crouch_dir(velocity.normalized())
			static_crouch_y = true

	# Death: pinned against a real wall by the chain's inward pull (can't move).
	# is_on_wall() reflects last frame's move_and_slide, which is fine for a timer.
	if is_on_wall() and MovementUtils.get_horizontal_vector(velocity).length() < CHAIN_STUCK_SPEED:
		chain_stuck_timer += delta
		if chain_stuck_timer >= CHAIN_STUCK_TIME:
			kill()
			return
	else:
		chain_stuck_timer = 0.0

	chain_active = true;

#endregion
	
func air_movement_normal(delta) -> void:
	
	var cur_speed_in_wish_dir = self.velocity.dot(wish_dir)
	
	var capped_speed = min((air_move_speed * wish_dir).length(), air_cap)
	if no_decell > 0.0: 
		
		check_wall_run(delta);
		return;
	
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
	
	wall_jump_count = maxf(0., wall_jump_count - delta);

	match movement_state:
		
		MOVEMENT_STATES.normal:
			air_movement_normal(delta);
			
		MOVEMENT_STATES.crouch:
			air_movement_crouch(delta);
			
		MOVEMENT_STATES.wallrun:
			_handle_footsteps(delta)
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
	
	wall_jump_count = 0.;
	
	match movement_state:
		MOVEMENT_STATES.normal:
			ground_movement_normal(delta)
			_handle_footsteps(delta)
		MOVEMENT_STATES.crouch:
			ground_movement_crouch(delta)
			
	pass

#endregion

func _physics_process(delta: float) -> void:
	
	transferred_wall_run = false;
	
	previous_velocity = velocity;
	motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	
	var on_floor = MovementUtils.really_on_floor(self);
	if on_floor:
		if to_hit_floor:
			to_hit_floor = false
			$LandEmitter.play() #TODO: why is this delayed?
		_last_frame_was_on_floor = Engine.get_physics_frames()
	else:
		to_hit_floor = true;
	
	InputController.update(delta);
	
	var input_dir = InputController.input_dir;
	wish_dir = self.global_transform.basis * Vector3(input_dir.x, 0., input_dir.y)
	
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
	
	original_velocity = velocity;
	original_transform = global_transform;
	original_position = global_position;
	
	print(original_velocity)
	
	apply_chain_constraint(delta);
	
	var on_wall_after_slide = false;
	
	if not MovementUtils._snap_up_stairs_check(self, %StairsAheadRayCast3D, delta, camera_component):
		move_and_slide();
		
		check_wall_transfer();
		
		on_wall_after_slide = is_on_wall();
		MovementUtils._snap_down_to_stairs_check(self, %StairsBelowRayCast3D, is_crouched, camera_component);
	
	if is_crouched : MovementUtils.slope_speedup(self)
	
	var redirect = true
	if on_wall_after_slide and original_velocity.y > 0 :
	
		var curr_time = phase_max_timer;
		var curr := [];
		var wall_at_ground;
		var raised_transform;
		var wall_at_raised;
		var phase = true;
		
		while true:
			
			wall_at_ground = test_move(global_transform, Vector3(original_velocity.x, 0, original_velocity.z) * curr_time)
			raised_transform = Transform3D(global_transform.basis, global_transform.origin + Vector3(0, velocity.y * curr_time, 0))
			wall_at_raised = test_move(raised_transform, Vector3(original_velocity.x, 0, original_velocity.z) * curr_time)
			
			if !wall_at_ground or wall_at_raised:
				if curr_time == phase_max_timer : phase = false;
				break;
			else:
				curr = [wall_at_ground, wall_at_raised, curr_time]
				curr_time -= phase_max_timer * 0.1;
				if curr_time <= 0: break

		if phase and curr[0] and not curr[1]:
			_start_phase_through(curr[2])
			velocity = original_velocity
			redirect = false;

	if redirect:
		if not transferred_wall_run:
			wall_redirect(original_velocity)
		floor_redirect(original_velocity)

	#Clamp player speed
	velocity = velocity.clamp(Vector3(-max_spd, -max_spd, -max_spd), Vector3(max_spd, max_spd, max_spd))
	
	pass


var phase_max_timer = 0.2;
var phase_timer = 0.0
var original_mask = 0

func _start_phase_through(timer : float = phase_max_timer):
	original_mask = collision_mask
	collision_mask = 0  # collide with nothing
	phase_timer = timer  # seconds of phasing

func _stop_phase_through():
	collision_mask = original_mask
	phase_timer = 0.0

func wall_redirect(original_velocity: Vector3) -> void:

	
	#Redirect direction when hitting a wall at an angle
	if is_on_wall():
		
		var wall_normal = get_wall_normal()

		var redirected = original_velocity;
		var res = {"redirected" : false, "speed" : original_velocity};
		if MovementUtils.get_horizontal_vector(velocity).length() <= MovementUtils.get_horizontal_vector(original_velocity).length():
		
			res = MovementUtils.redirect_velocity(original_velocity, wall_normal, 0.1);
			
			if res.redirected:
				
				if is_crouched:
					
					if MovementUtils.really_on_floor(self) : 
						temp_crouch_dir = MovementUtils.get_horizontal_vector(velocity).normalized();
					else:
						crouch_dir = MovementUtils.get_horizontal_vector(velocity).normalized();
					
				res.speed.y = jump_velocity + (res.speed.y - jump_velocity) * 0.6 if res.speed.y > jump_velocity else res.speed.y; 	
				velocity = res.speed;
				#print("redirected yeah %s %s %s" % [velocity, original_velocity, wall_normal])
				
		if velocity.length() == 0. or (wall_normal.dot(original_velocity.normalized()) < -0.7 and !res.redirected and is_crouched):
			force_uncrouch();

	else:
		temp_crouch_dir = Vector3.ZERO

func floor_redirect(original_velocity : Vector3) -> void:
	#Redirect speed when hitting the floor at an angle while crouching
	
	if is_crouched and MovementUtils.really_on_floor(self):
		
		if velocity.length() < original_velocity.length():
			
			var res = MovementUtils.redirect_velocity(original_velocity, get_floor_normal());
			velocity = res.speed * (1. if crouch_dir.y == 0 else 0.4);
			
			if crouch_dir.y < 0:
			
				var spd = velocity.length();
				var new_dir = MovementUtils.redirect_velocity(crouch_dir, Vector3.UP, 0.3 / (spd / 10. if spd > 15 else 1.));
				
				if new_dir.speed == crouch_dir : 
					force_uncrouch()
				else:	
					crouch_dir = new_dir.speed;
					
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

func is_stunned() -> bool:
	return stunned;

func stun(time : float = stun_timeout) -> void:
	stunned = true;
	stun_timer = get_tree().create_timer(stun_timeout);
	stun_timer.timeout.connect(_on_stun_timeout);
	
	movement_state = MOVEMENT_STATES.normal;
	
	# TODO: we might need to check for pending states before assigning this one
	
	LevelController.gameplay_HUD_left.fade_dashes(true);
	LevelController.gameplay_HUD_left.fade_telekinesis(true);
	
func _on_stun_timeout() -> void:
	stunned = false;
	
	LevelController.gameplay_HUD_left.fade_dashes(false);
	LevelController.gameplay_HUD_left.fade_telekinesis(false);

func _process(delta: float) -> void:
	
	if phase_timer > 0.:
		phase_timer -= delta
		
		# Reactivate early if hitting a new wall
		if phase_timer <= 0.:
			_stop_phase_through()
			
	if _mouse_delta != Vector2.ZERO:
		var sensitivity = (
			look_sensitivity
			* GameConfig.config.get_value("general", "mouse_sensitivity")
			* GameController.main_gameplay.gameplay_viewport_container.stretch_shrink
		)
		rotate_y(-_mouse_delta.x * sensitivity * GameJuice.get_time_scale())
		camera_component.rotate_x(-_mouse_delta.y * sensitivity * GameJuice.get_time_scale(), deg_to_rad(-90), deg_to_rad(90))
		_mouse_delta = Vector2.ZERO
	
	camera_component.update(delta);
	camera_component._slide_camera_smooth_back_to_origin(delta, self.velocity.length(), get_move_speed())
	
	if is_wall_running():
		var tilt_dir = -wall_run_normal.dot(global_transform.basis.x)
		camera_component.set_camera_tilt(deg_to_rad(CAMERA_WALLRUN_TILT_ANGLE) * tilt_dir)
	else:
		camera_component.set_camera_tilt(0.);

	weapon_manager.update(delta)
	if LevelController.weapon_hud: 
		LevelController.weapon_hud.refresh(weapon_manager);
	
	#rocket_launcher_component.update(delta)
	telekinesis_component.update(delta)
	
	_handle_controller_look_input(delta)
	
	if InputController.fire_primary():
		weapon_manager.fire_primary()
		if !just_fired:
			just_fired = true
	else:
		if just_fired:
			just_fired = false
			$StopFiringEmitter.play()

	for slot in range(1, weapon_manager.weapons.size() + 1):
		if InputController.weapon_slot(slot):
			weapon_manager.set_active_weapon(slot - 1)

	var scroll_dir = InputController.weapon_scroll()
	if scroll_dir != 0:
		weapon_manager.cycle_weapon(scroll_dir)
	
	#if InputController.fire_rocket():
		#rocket_launcher_component.launch_rocket()
	
	if InputController.dash() and !is_dashing() and !is_stunned() and LevelController.player_abilities["dash"]:
		var dash_dir = wish_dir if wish_dir != Vector3.ZERO else MovementUtils.get_horizontal_vector(MovementUtils.get_look_direction_vector(LevelController.player_camera))
		dash_component.dash(dash_dir);
		movement_state = MOVEMENT_STATES.dash;
		$DashEmitter.play()
		
		if is_crouched : change_crouch_dir(dash_dir);
		
		InputController.reset_dash_buffer();
		
	_handle_crouch(delta);

	if InputController.do_kick():
		kick_module.kick();
	
	if InputController.launch_enemy() and !is_stunned() and LevelController.player_abilities["telekinesis"]:
		telekinesis_component.launch_enemy()
	
	var val = velocity.length() / Vector3(max_spd, max_spd, max_spd).length();
	
	camera_component.updateFOV(delta, val * 2)
	
	health_component.set_resistance("speed_resistance", max(0.25, 1 - 0.25 * (velocity.length()/8.)))
	
	pass

func play_damaged_sound():
	$DamagedEmitter.play()
