class_name FloaterEnemy extends ParentEnemy

@onready var state_chart: StateChart = %StateChart

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
	
	float_up();
	global_position.y += random.randf_range(-1, 1);
	
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	
	return
	
	
func float_up():
	var tween = create_tween()
	tween.tween_property(self, "float_offset", 0.003, 5).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(float_down)

func float_down():
	var tween = create_tween()
	tween.tween_property(self, "float_offset", -0.003, 5).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(float_up)

func _physics_process(delta):
	# Apply your float_offset + velocity together
	
	set_power_kickable(dead)
	
	material_manager_component.set_outline(get_power_kick_outline());
	
	basic_enemy_movement(delta, true, true);
	

func set_power_kickable(val : bool) -> void:
	
	power_kickable = val;

#region helpers

func look_at_position(pos : Vector3) -> void:
	look_at(pos, Vector3.UP)	
	
#endregion	

#region dead state

func _on_died() -> void:
	
	soft_collide = false;
	dead = true;
	state_chart.send_event("ToDead")
	
	velocity = Vector3.ZERO
	velocity.y = 2;
	
	motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	
	knockback_multiplier = 1.0;
	vertical_knockback_multiplier = 1.0;

#endregion




func parry() -> void:
		
	
	super.parry()
	
	var kill = health_component.take_damage(100);
	LevelController.power_kick(20, 12, kill, true);
	

func get_power_kick_outline() -> bool:
	
	return is_power_kickable() or is_parryable();

func _on_dead_state_processing(delta: float) -> void:

	
	%MeshInstance3D.get_active_material(0).albedo_color = Color(1, 0, 0);
	
	self.velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta;
	
	if MovementUtils.really_on_floor(self):
		queue_free()
	
	
	pass # Replace with function body.


func _on_floating_state_processing(delta: float) -> void:
	
	
	
	velocity = velocity.lerp(Vector3.ZERO, hover_factor)
	position += Vector3(0, float_offset, 0) 
	
	pass # Replace with function body.
