class_name BlasterEnemy extends ParentEnemy

@onready var state_chart: StateChart = $StateChart

@export var min_charge_time : float = 4.;
@export var max_charge_time : float = 8.;
@export var critical_threshold : float = 1.5;


var charge_time : float = 0.0;
var warning_active := false;

@export var max_cooldown_time : float = 20.;
var cooldown_time : float = 0.0;


func to_idle() -> void:
	remove_warning();
	state_chart.send_event("toIdle");
	
func _on_idle_state_processing(delta: float) -> void:
	
	if inside_detection():
		start_charging()
	
	pass # Replace with function body.

func start_charging() -> void:
	
	charge_time = random.randf_range(min_charge_time, max_charge_time)
	
	state_chart.send_event("toCharge");
	
	
func _on_charging_state_processing(delta: float) -> void:
	
	if !inside_view(): to_idle();
	
	charge_time = maxf(charge_time - delta, 0.0);
	
	#if charge_time <= critical_threshold:
	
	if !warning_active:
		warning_active = true
		LevelController.gameplay_HUD.add_blaster_warning(self)
	else:
		if charge_time < critical_threshold:
			LevelController.gameplay_HUD.set_blaster_warning_critical(self);
		
		
	if charge_time == 0.:
		fire();
		to_recovery();
	
	pass

func remove_warning() -> void:
	if warning_active:
		warning_active = false
		LevelController.gameplay_HUD.remove_blaster_warning(self)


@export var blaster_projectile_scene : PackedScene;
func fire() -> void:
	
	var blast = LevelController.create_scene(blaster_projectile_scene);
	
	var dist = LevelController.distance_to_player(attack_origin.global_position).length();
	var gap = attack_offset.global_position.distance_to(attack_origin.global_position);
	
	var time = (dist - gap) / blast.speed;
	var pos = MovementUtils.get_future_position(LevelController.player, time)
	
	attack_origin.look_at(pos, Vector3.UP);
	blast.global_transform = attack_offset.global_transform
	blast.set_speed(LevelController.distance_to_player(global_position).normalized());
	
	
	pass;

func to_recovery() -> void:
	cooldown_time = max_cooldown_time;
	state_chart.send_event("toRecovery");
	remove_warning();

func _on_recovery_state_processing(delta: float) -> void:
	
	cooldown_time = maxf(cooldown_time - delta, 0.0);
	
	if cooldown_time == 0.0:
		to_idle();
	
	pass # Replace with function body.
