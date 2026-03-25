class_name aerial_enemy extends ParentEnemy

var target : Node3D;

var follow_speed : float = 6;
@export var hover_speed: float = 1;
@export var hover_factor: float = 0.05;
var initial_velocity : Vector3 = Vector3(0, -hover_speed, 0);
var target_inverse_velocity : Vector3 = Vector3(0, hover_speed, 0);
var last_frame_position := global_position;

const MAX_STEP_HEIGHT = 0.5;

@export var attack_range := 1.5;
@export var attack_max_delay := 0.8;
@export var attack_move := 16.;

var attack_delay : float = 0.;

@export var max_recovery_delay := 0.8;
var recovery_delay : float = 0.;
var charging_attack := false;

# const AERIAL_ENEMY_ATTACK = preload("TODO")

func _ready() -> void:
	super._ready();
	
	safe_margin = 0.05
	
	target = LevelController.player
	velocity = initial_velocity
	
	%NavigationAgent3D.velocity_computed.connect(_on_velocity_computed);
	
	health_component.setup(100)
	health_component.connect("died", _on_died)
	
	return
	
	
func _physics_process(delta: float) -> void:

	MovementUtils.soft_collide(self, %PersonalSpaceArea, delta)
	if abs(velocity.y) >= abs(target_inverse_velocity.y) - hover_factor:
		target_inverse_velocity = -target_inverse_velocity
		
	velocity = velocity.lerp(target_inverse_velocity, hover_factor)
	
	move_and_slide()
	
#region helpers

func look_at_position(pos : Vector3) -> void:
	look_at(pos, Vector3.UP)	
	
#endregion	

#region dead state

func _on_died() -> void:
	
	super._on_died()
	
	%StateChart.send_event("toDead")
	stop_navigation()
	%WorldModel.rotation_degrees.x = 90
	dead = true;

#endregion

#region follow state

func _on_velocity_computed(safe_velocity : Vector3) -> void:
	
	if blown_away: return
	if %NavigationAgent3D.is_navigation_finished(): return
	
	velocity.x = safe_velocity.x
	velocity.z = safe_velocity.z

func _on_follow_state_physics_processing(delta: float) -> void:

	if !inside_view(): 
		%StateChart.send_event("toIdle")
		stop_navigation();
		return;

	if not target:
		return
	
	update_navigation();
	
	pass # Replace with function body.

#endregion

#region attack state

func start_attack() -> void:
	attack_delay = attack_max_delay;
	%StateChart.send_event("toAttack");

func _on_attack_state_physics_processing(delta: float) -> void:
	
	look_at_position(Vector3(target.global_position.x, global_position.y, target.global_position.z))
	
	var color = Color(1, 1, 1).lerp(Color(1, 0, 1), 1 - attack_delay/attack_max_delay)
	%MeshInstance3D.get_active_material(0).albedo_color = color
	
	charging_attack = true;
	attack_delay = max(attack_delay - delta, 0)
	
	if attack_delay <= 0.2:
		set_open_to_parry(true)
	
	if attack_delay == 0:
		
		# TODO: var attack = FLOOR_ENEMY_ATTACK.instantiate();
		# attack.global_position = attack_origin.global_position;
		# attack.rotation = rotation;
		# attack.set_creator(self);
		
		# LevelController.current_level.add_child(attack)
		velocity += MovementUtils.get_look_direction_vector(self) * attack_move;
		
		start_recovery();
		
	
	pass # Replace with function body.

#endregion

#region recovery state

func start_recovery() -> void:
	set_open_to_parry(false);
	charging_attack = false;
	recovery_delay = max_recovery_delay;
	%StateChart.send_event("toRecovery");

func _on_recovery_state_physics_processing(delta: float) -> void:
	
	recovery_delay = max(recovery_delay - delta, 0)
	
	if recovery_delay == 0:
		%StateChart.send_event("toIdle");
		
	pass # Replace with function body.
	
#endregion
	
#region blown away state
	
func blow_away() -> void:
	
	if is_dead() : return
	
	super.blow_away()
	%StateChart.send_event("toBlownAway");
	
func _on_blown_away_state_physics_processing(delta: float) -> void:
	
	if last_frame_position == global_position:
		blown_away = false;
		%StateChart.send_event("toIdle");
	
	last_frame_position = global_position;
	pass # Replace with function body.

#endregion

#region idle state

func _on_idle_state_physics_processing(delta: float) -> void:
	
	if inside_detection() : 
		%StateChart.send_event("toFollow");
	
	pass # Replace with function body.

#endregion

#region navigation

func update_navigation() -> void:
	
	var distance = global_position.distance_to(target.global_position)

	if !blown_away and distance <= attack_range:
		stop_navigation()
		start_attack()
		return
		
	%NavigationAgent3D.target_position = target.global_position
	
	if %NavigationAgent3D.is_navigation_finished():
		%NavigationAgent3D.velocity = Vector3.ZERO
		return
		
	var next_pos = %NavigationAgent3D.get_next_path_position()
	var direction = (next_pos - global_position).normalized()
	
	%NavigationAgent3D.velocity = direction * follow_speed;

	var pos = global_position + MovementUtils.get_horizontal_vector(%NavigationAgent3D.velocity);
	if blown_away :
		look_at(global_position + MovementUtils.get_horizontal_vector(-self.velocity), Vector3.UP)
	else:
		if pos != global_position : look_at(global_position + MovementUtils.get_horizontal_vector(%NavigationAgent3D.velocity), Vector3.UP)	

func start_navigation() -> void:
	%NavigationAgent3D.target_position = target.global_position;
	
func stop_navigation() -> void:
	%NavigationAgent3D.velocity = Vector3.ZERO
	velocity = Vector3.ZERO
	%NavigationAgent3D.target_position = global_position

#endregion



func parry() -> void:
		
	if has_been_parryed : return;
	
	super.parry()
	
	var kill = health_component.take_damage(100);
	LevelController.power_kick(20, 12, kill, true);
	
