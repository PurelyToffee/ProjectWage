class_name BrawlerEnemy extends ParentEnemy

var target : Node3D;

var last_frame_position := global_position;
var stuck_counter : int = 0;
var is_stuck : bool = false;

@export var follow_speed : float = 6;
@export var attack_range := 1.5;
@export var attack_max_delay := 0.3;
@export var attack_move := 16.;
@export var max_recovery_delay := 0.8;
@export var parry_time := 0.2;

@export var attack_scene : PackedScene;
var attack : Area3D = null;

var attack_delay : float = 0.;


var recovery_delay : float = 0.;
var charging_attack := false;

func _ready() -> void:
	super._ready();
	
	safe_margin = 0.05
	
	target = LevelController.player
	
	%NavigationAgent3D.velocity_computed.connect(_on_velocity_computed);
	
	return
	
	
func _physics_process(delta: float) -> void:
	
	%MeshInstance3D.get_active_material(0).albedo_color = Color(1, 1, 1);
	
	super._physics_process(delta);
	
	basic_enemy_movement(delta)

	set_power_kickable(is_blown_away());

	
#region helpers

func stuck_jump() -> void:
	
	is_stuck = last_frame_position == global_position;
		
	if  !%NavigationAgent3D.is_navigation_finished():
		if stuck_counter >= 5:
			self.velocity.y += 2;
			stuck_counter = 0;
		else:
			var val = int(is_stuck)
			stuck_counter = (stuck_counter + val) * val;
			last_frame_position = global_position
	
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

func start_follow() -> void:
	%StateChart.send_event("toFollow");

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
	
	target = LevelController.player;
	
	if MovementUtils.really_on_floor(self):
		stuck_jump();
	
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
	
	if attack_delay <= parry_time:
		set_parryable(true)
	
	if attack_delay == 0:
		
		attack = attack_scene.instantiate();
		attack_origin.look_at(LevelController.player.global_position, Vector3.UP);
		attack.global_transform = attack_offset.global_transform
		attack.set_creator(self);
		
		LevelController.current_level.add_child(attack)
		velocity += MovementUtils.get_look_direction_vector(self) * attack_move;
		
		start_recovery();
		
	
	pass # Replace with function body.

#endregion

#region recovery state

func start_recovery() -> void:
	set_parryable(false);
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

		start_recovery();
	
	last_frame_position = global_position;
	pass # Replace with function body.

#endregion

#region idle state

func _on_idle_state_physics_processing(delta: float) -> void:
	
	if inside_detection() : 
		start_follow();
	
	pass # Replace with function body.

#endregion


#region navigation

func update_navigation() -> void:
	
	%NavigationAgent3D.target_position = MovementUtils.get_future_position(target, attack_max_delay * 0.8)
	
	var distance = attack_origin.global_position.distance_to(%NavigationAgent3D.target_position)
	
	if !blown_away and !%NavigationAgent3D.is_navigation_finished() and distance <= attack_range:
		stop_navigation()
		start_attack()
		return
	
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
	if !kill : start_recovery();
