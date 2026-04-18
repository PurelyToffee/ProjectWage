class_name SpawnerEnemy extends ParentEnemy

@onready var state_chart: StateChart = %StateChart
@onready var navigation_agent_3d: NavigationAgent3D = %NavigationAgent3D

@export var attack_scene : PackedScene;

@export var safe_distance := 20.0;
@export var spawn_count_max := 5;
@export var spawn_count_min := 3;
@export var attack_max_delay := 0.5;
@export var attack_max_cooldown := 8.0;

@export var max_attack_count := 8;
var current_attack_count := 0;


var attack_cooldown := 0.0;
var attack_delay := 0.0;

var moving := false;
var move_spd := 6.0;

var target := Vector3.ZERO;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	super._ready()
	
	navigation_agent_3d.velocity_computed.connect(_on_velocity_computed);
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	basic_enemy_movement(delta)
	pass


func to_idle() -> void:
	
	blown_away = false;
	state_chart.send_event("toIdle");

func _on_idle_state_processing(delta: float) -> void:
	
	if inside_detection():
		to_active();
	
	pass # Replace with function body.

func to_active() -> void:
	
	state_chart.send_event("toActive");

func _on_active_state_processing(delta: float) -> void:
	
	if !inside_view():
		to_idle();
	
	var dist_to_player = get_center_point().global_position.distance_to(
			LevelController.player.get_center_point().global_position 
		);
	
	var in_safe_distance = dist_to_player > safe_distance;
	
	if !in_safe_distance : 
		update_navigation();
		attack_delay = attack_max_delay;
		return;
	
	
	attack_cooldown = maxf(attack_cooldown - delta, 0.);
	
	stop_navigation();
	var direction = (global_position - LevelController.player.global_position).normalized();
	look_at(global_position + MovementUtils.get_horizontal_vector(direction), Vector3.UP);
	
	if attack_cooldown == 0.0:
		
		attack_delay = maxf(attack_delay - delta, 0.0);
		
		if attack_delay == 0.0:
			var count = random.randi_range(spawn_count_min, spawn_count_max);
			count = min(count, max_attack_count - current_attack_count);
			
			var step = (2.0 * PI) / count;
			
			while count > 0.:

				var spawn_dir = Vector3(cos(step * count), 0.2, sin(step * count));
				var pos = get_center_point().global_position + spawn_dir;
				
				var attack = LevelController.create_scene(attack_scene);
				attack.global_position = pos;
				attack.velocity = spawn_dir * 4; 
				attack.velocity.y += 3;
				
				count -= 1;
		
			attack_cooldown = attack_max_cooldown;
	

func _on_velocity_computed(safe_velocity : Vector3) -> void:
	
	if blown_away: return
	if navigation_agent_3d.is_navigation_finished(): return
	
	velocity.x = safe_velocity.x
	velocity.z = safe_velocity.z

func move() -> void:
	if moving : return;
	
	
	
	moving = true;


func stop_moving() -> void:
	
	if !moving : return;
	
	moving = false;


#region navigation

func get_safe_position() -> Vector3:
	
	var direction = -LevelController.distance_to_player(global_position, false).normalized();
	var safe_pos = global_position + direction * safe_distance;

	var nav_map = get_world_3d().navigation_map
	return NavigationServer3D.map_get_closest_point(nav_map, safe_pos);


func update_navigation() -> void:
	
	target = get_safe_position();
	navigation_agent_3d.target_position = target;

	var distance = global_position.distance_to(target)

	if navigation_agent_3d.is_navigation_finished():
		navigation_agent_3d.velocity = Vector3.ZERO
		return
		
	var next_pos = navigation_agent_3d.get_next_path_position()
	var direction = (next_pos - global_position).normalized()
	
	navigation_agent_3d.velocity = direction * move_spd;

	var pos = global_position + MovementUtils.get_horizontal_vector(navigation_agent_3d.velocity);
	if blown_away :
		look_at(global_position + MovementUtils.get_horizontal_vector(-self.velocity), Vector3.UP)
	else:
		if pos != global_position : look_at(global_position + MovementUtils.get_horizontal_vector(navigation_agent_3d.velocity), Vector3.UP)	

func start_navigation() -> void:
	navigation_agent_3d.target_position = target;
	
func stop_navigation() -> void:
	navigation_agent_3d.velocity = Vector3.ZERO
	velocity = Vector3.ZERO
	navigation_agent_3d.target_position = global_position

#endregion

	
func _on_died() -> void:
	
	super._on_died()
	
	state_chart.send_event("toDead")
	stop_navigation()
	%WorldModel.rotation_degrees.x = 90
	dead = true;


func _on_dead_state_processing(delta: float) -> void:
	pass # Replace with function body.


func blow_away() -> void:
	
	if is_dead() : return
	
	super.blow_away()
	state_chart.send_event("toBlownAway");
	

func _on_blown_away_state_processing(delta: float) -> void:
	
	if MovementUtils.really_on_floor(self):
		to_idle();
	
	pass # Replace with function body.
