class_name TeleporterEnemy extends ParentEnemy

@onready var fear_area: Area3D = %FearArea
@export var tp_clusters : Array[Node3D] = [];
@onready var state_chart: StateChart = %StateChart
@onready var model: MeshInstance3D = %MeshInstance3D

var tp_nodes : Array[Node3D] = [];

@export var safe_distance := 4.0;

var teleporting := false;
@export var max_teleport_cooldown := 6.0;
var teleport_cooldown := 0.0;
var alpha := 1.0;
var alpha_spd := 2.0;

@export var gone_min_timer := 1.0;
@export var gone_max_timer := 2.0;
var gone_timer := 0.0;
var is_afraid := false;

const TELEPORTER_NODE = preload("uid://b8kfaxsy6v6e6")
var current_node : TeleporterNode = null;

var was_attacking := false;

var default_color;

func _ready() -> void:
	
	super._ready();
	
	default_color = model.get_active_material(0).albedo_color;
	
	await get_tree().process_frame
	current_node = TELEPORTER_NODE.instantiate();
	current_node.global_position = global_position;	
	
	current_node.occupy();
	tp_nodes.append(current_node)
	
	LevelController.current_level.add_child(current_node);
	
	extract_tp_nodes();

func extract_tp_nodes() -> void:
	
	for node in tp_clusters:
		
		if node is Node3D:
			for tp_node : TeleporterNode in node.get_children():
				tp_nodes.append(tp_node);
		elif node is TeleporterNode:
			tp_nodes.append(node);

func too_close(object : Node3D = get_center_point(), target : Node3D = LevelController.player.get_center_point()) -> bool:
	
	return object.global_position.distance_to(target.global_position) < safe_distance;
	

func _physics_process(delta: float) -> void:
	
	super._physics_process(delta)
	
	teleport_cooldown = maxf(teleport_cooldown - delta, 0.0);
	
	basic_enemy_movement(delta);
		
	set_alpha(alpha);

func set_alpha(val : float) -> void:
	var color = model.get_active_material(0).albedo_color;
	color.a = val;
	model.get_active_material(0).albedo_color = color


func reset() -> void:
	
	if is_dead() : return;
	
	state_set_event(state_chart, "toIdle");
	attack_counter = 0.0;
	attack_cooldown = 0.0;
	attack_delay = 0.0;
	is_afraid = false;
	
	alpha = 1.0;
	
	health_component.set_health(health_component.get_max()/1.5)

func _on_idle_state_processing(delta: float) -> void:
	
	check_scare_teleport();
	
	if !teleporting and inside_detection():
		start_attack()
	
	pass # Replace with function body.


@export var attack_max_cooldown := 3.0;
@export var attack_min_cooldown := 2.0;

var attack_cooldown := 0.0;

@export var max_attacks_per_cycle := 5;
@export var min_attacks_per_cycle := 2;
@export var attack_max_delay := 0.4;

var attack_delay := 0.0;
var attack_counter := 0.0;

@export var attack_scene : PackedScene;

func start_attack() -> void:
	
	state_chart.send_event("toAttack");

func _on_attack_state_processing(delta: float) -> void:
	
	look_at_position(Vector3(LevelController.player.global_position.x, global_position.y, LevelController.player.global_position.z))
	
	
	check_scare_teleport();
	
	if !inside_view():
		if teleport_out():
			was_attacking = true
		else:
			reset();
	
	if attack_counter == 0.0:
	
		attack_cooldown = maxf(attack_cooldown - delta, 0.0);
		
		if attack_cooldown == 0.0:
			attack_counter = random.randi_range(min_attacks_per_cycle, max_attacks_per_cycle);
			attack_delay = attack_max_delay
			
	else:
		
		attack_delay = maxf(attack_delay - delta, 0);
		
		if attack_delay == 0.0:
			attack_counter -= 1;
			
			
			var attack = LevelController.create_scene(attack_scene)
			attack_origin.look_at(LevelController.player.get_center_point().global_position, Vector3.UP);
			attack.global_transform = attack_offset.global_transform
			attack.set_speed(LevelController.distance_to_player(global_position).normalized())
			
			attack_delay = attack_max_delay;
			
			if attack_counter == 0.0:
				attack_cooldown = random.randf_range(attack_min_cooldown, attack_max_cooldown);
	
	
	pass # Replace with function body.



func _on_died() -> void:
	start_stun();
	
	
#region stunned

@export var max_stun_time := 5.0;
var stun_time = 0.0;

func start_stun() -> void:
	stun_time = max_stun_time;
	state_set_event(state_chart, "toStunned");
	
	velocity.y = 3;
	
	alpha = 1.0;
	model.get_active_material(0).albedo_color = Color(0.441, 0.202, 0.441, 1.0)

func _on_stunned_state_processing(delta: float) -> void:
	
	stun_time = maxf(stun_time - delta, 0.0);
	
	if stun_time == 0.0:
		model.get_active_material(0).albedo_color = default_color;
		reset();
	
	pass

func get_power_kickable_state() -> bool:
	return stun_time > 0.0;


func power_kick() -> void:
	
	if arena:
		arena.set_dead(self);
	
	state_set_event(state_chart, "toDead");
	dead = true;
	
	model.get_active_material(0).albedo_color = Color(1., 1., 1.)
	
	LevelController.power_kick();
	LevelController.power_kick_score(is_dead(), !MovementUtils.really_on_floor(self))
	
	%WorldModel.rotation_degrees.x = 90;
	super._on_died();

#endregion

#region dead

func _on_dead_state_processing(delta: float) -> void:
	pass # Replace with function body.

#endregion		


#region teleport out

func check_scare_teleport() -> void:
	if !dead and !teleporting and too_close():
		teleport_out(true);

func teleport_out(afraid : bool = false) -> bool:
	
	if !afraid and get_closest_node() == null : return false;
	if teleport_cooldown > 0. : return false;
	
	is_afraid = afraid;
	teleporting = true;
	state_set_event(state_chart, "toTpOut");
	
	return true;

func _on_tp_out_state_processing(delta: float) -> void:
	
	alpha = maxf(alpha - alpha_spd * delta, 0.);
	
	if alpha == 0.:
		disappear();
	
	pass # Replace with function body.

#endregion

#region teleport in
func teleport_in() -> void:
	teleporting = true;
	state_set_event(state_chart, "toTpIn");

func _on_tp_in_state_processing(delta: float) -> void:
	
	alpha = minf(alpha + alpha_spd * delta, 1.);
	
	if alpha == 1.0:
		teleporting = false;
		teleport_cooldown = max_teleport_cooldown;
		
		reset();
		if was_attacking and inside_view():
			state_set_event(state_chart, "toAttack");
	
	pass # Replace with function body.

#endregion

func disappear() -> void:
	state_set_event(state_chart, "toGone");
	gone_timer = random.randf_range(gone_min_timer, gone_max_timer);

func sort_nodes(a, b) -> bool:
	
	#Sorts nodes by distance to player, from closest to furthest
	
	var a_dist = MovementUtils.distance_between_points(a.global_position, LevelController.player.global_position);
	var b_dist = MovementUtils.distance_between_points(b.global_position, LevelController.player.global_position);
	
	return a_dist < b_dist;

func _on_gone_state_processing(delta: float) -> void:
	
	health_component.set_immortal(true);
	gone_timer = maxf(gone_timer - delta, 0.);
	if gone_timer == 0.:

		var node = get_closest_node();
		
		if node:
			current_node.leave();
			current_node = node.teleport_to(self);
			
		teleport_in();
		health_component.set_immortal(false);

func get_closest_node(target : Node3D = LevelController.player) -> TeleporterNode:
		
	var arr = [];
	for n in tp_nodes:
		if !n.is_occupied():
			arr.append(n);
		
	arr.sort_custom(sort_nodes)
	for n in arr:
			
			var curr_dist = global_position.distance_to(target.get_center_point().global_position);
			var future_dist = n.global_position.distance_to(target.get_center_point().global_position)
			
			if !is_afraid and curr_dist < future_dist: return null;
			
			if !too_close(n):
				return n;

	return null;
