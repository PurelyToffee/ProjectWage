class_name RocketParent extends RigidBody3D

var free := false;

@export var speed := 40.0
@export var damage_target := "player"
@export var damage := 15.0;

@export var parryable := false;
@export var parryable_grace_period := 0.1;
var grace := false;
var grace_period := 0.0;

var pending_speed : Vector3 = Vector3.ZERO

func _ready():
	set_speed();
	
func set_speed() -> void:
	pending_speed = -transform.basis.z * (maxf(LevelController.player.velocity.length() + 8., speed))

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if pending_speed != Vector3.ZERO:
		state.linear_velocity = pending_speed
		pending_speed = Vector3.ZERO

func is_parryable() -> bool:
	return parryable and grace;

func reset() -> void:
	grace = false;
	grace_period = 0;
	free = false;

func _physics_process(delta: float) -> void:
	
	if parryable and grace:
		grace_period = maxf(grace_period - delta, 0.);
		
		if grace_period == 0.:
			LevelController.player.take_damage(damage)
			queue_free();
		else:
			global_position = LevelController.get_player_center().global_position;
	else:
		if free: queue_free();

func parry(dir : Vector3, new_damage_target : String = "enemy") -> void:
	
	global_position = LevelController.player_camera.global_position;
	
	look_at(global_position + dir);
	set_speed();
	damage_target = new_damage_target;
	
	LevelController.power_kick();
	LevelController.parry_score();
	
	reset();
	
	
func damage_player() -> void:
	
	if parryable:
		grace_period = parryable_grace_period;
		grace = true;
		return;
					
	LevelController.player.take_damage(damage)
	
func damage_default(body) -> void:
	body.take_damage(damage);

func _on_body_entered(body: Node) -> void:
	
	if body.is_in_group(damage_target):
		
		match(damage_target):
			
			"player": damage_player()
			
			_: damage_default(body);

	
	free = true;
