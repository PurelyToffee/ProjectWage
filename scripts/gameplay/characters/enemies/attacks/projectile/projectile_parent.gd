class_name ProjectileParent extends RigidBody3D

var free := false;

@export var speed := 40.0
@export var damage_target := "player"
@export var damage := 15.0;

@export var parryable := false;
@export var parryable_grace_period := 0.1;
var grace := false;
var grace_period := 0.0;

var pending_speed : Vector3 = Vector3.ZERO
var curr_dir : Vector3 = Vector3.ZERO

func set_speed(dir : Vector3) -> void:
	curr_dir = dir;
	linear_velocity = curr_dir * (maxf(LevelController.player.velocity.length() + 8., speed))

func launch(direction: Vector3, _launch_speed: float = 0.0) -> void:
	set_speed(direction.normalized())


func is_parryable() -> bool:
	return parryable and grace;

func reset() -> void:
	grace = false;
	grace_period = 0;
	free = false;

func _physics_process(delta: float) -> void:

	_drive_motion(delta)
	_update_grace(delta)

	if free: queue_free();

func _drive_motion(_delta: float) -> void:
	set_speed(curr_dir)

func _update_grace(delta: float) -> void:
	if parryable and grace:
		grace_period = maxf(grace_period - delta, 0.);

		if grace_period == 0.:
			damage_player(true);
		else:
			global_position = LevelController.get_player_center().global_position;

func parry(dir : Vector3, new_damage_target : String = "enemy") -> void:


	global_position = LevelController.player_camera.global_position;
	look_at(global_position + dir);

	set_speed(dir);
	damage_target = new_damage_target;

	LevelController.parry_score();

	print("parry succesfful")

	reset();


func damage_player(skip : bool = false) -> void:

	if !skip and parryable:
		grace_period = parryable_grace_period;
		grace = true;
		return;

	LevelController.player.take_damage(damage)

func damage_default(body) -> void:

	if !body.is_in_group("damageable"): return;


func _on_body_entered(body: Node) -> void:

	if grace : return;

	if _handle_body_contact(body):
		free = true;


func _on_area_3d_body_entered(body: Node3D) -> void:

	if _handle_body_contact(body):
		free = true;

func _handle_body_contact(body: Node) -> bool:

	var damaged := false

	if body.is_in_group(damage_target):

		match(damage_target):

			"player":
				damage_player()
				damaged = true
				if grace: return false

			_:
				damage_default(body)
				damaged = true

	if not damaged:
		damage_default(body)

	return true
