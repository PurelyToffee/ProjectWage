class_name aerial_enemy extends ParentEnemy

var target : Node3D;

var follow_speed : float = 6;
@export var hover_speed: float = 1;
@export var hover_factor: float = 0.05;
var initial_velocity : Vector3 = Vector3(0, -hover_speed, 0);
var target_inverse_velocity : Vector3 = Vector3(0, hover_speed, 0);
var last_frame_position := global_position;


@export var attack_range := 1.5;
@export var attack_max_delay := 0.8;
@export var attack_move := 16.;

var attack_delay : float = 0.;

@export var max_recovery_delay := 0.8;
var recovery_delay : float = 0.;
var charging_attack := false;

var float_offset := 0.0

# const AERIAL_ENEMY_ATTACK = preload("TODO")

func _ready() -> void:
	super._ready();
	
	safe_margin = 0.05
	
	target = LevelController.player
	velocity = initial_velocity
	
	health_component.setup(50)
	health_component.connect("died", _on_died)
	
	float_up();
	
	return
	
	
func float_up():
	var tween = create_tween()
	tween.tween_property(self, "float_offset", 0.005, 5).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(float_down)

func float_down():
	var tween = create_tween()
	tween.tween_property(self, "float_offset", -0.005, 5).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(float_up)

func _physics_process(delta):
	# Apply your float_offset + velocity together
	
	print(float_offset)
	
	MovementUtils.soft_collide(self, %PersonalSpaceArea, delta)

	velocity = velocity.lerp(Vector3.ZERO, hover_factor)
	position += Vector3(0, float_offset, 0) 
	
	move_and_slide()
	
	
#region helpers

func look_at_position(pos : Vector3) -> void:
	look_at(pos, Vector3.UP)	
	
#endregion	

#region dead state

func _on_died() -> void:
	
	super._on_died()
	queue_free();

#endregion




func parry() -> void:
		
	if has_been_parryed : return;
	
	super.parry()
	
	var kill = health_component.take_damage(100);
	LevelController.power_kick(20, 12, kill, true);
	
