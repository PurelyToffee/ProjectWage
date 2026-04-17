extends Node3D

var current_level : Node3D;
var gameplay_viewport_container : SubViewportContainer;

var level_state : int = level_states.RUNNING;
enum level_states {
	START,
	RUNNING,
	PAUSED,
	END,
	DEAD
}

#region Weapons

const DualMacTen = preload("uid://bolqjo6l5kov7")

#endregion

func _process(delta : float) -> void:
	if !timer_is_frozen(): level_timer += delta;
	
	if !game_is_paused():
		level_score_display = level_score_real;
	
	if InputController.escape():
		
		if !LevelController.game_is_paused():
			LevelController.pause_game();
		else:
			LevelController.unpause_game();
	
#region helpers related to player

func distance_to_player(pos : Vector3, center : bool = true) -> Vector3:
	
	return (player.get_center_point().global_position if center else player.global_position) - pos;

func get_player_center() -> Node3D:
	return player.get_center_point();

#endregion
	

#region timer 

var level_timer : float = 0.0;
var timer_frozen : bool = false;

func time_to_str(time: float = level_timer):
	return "%02d:%02d:%03d" % [
		int(floor(time / 60.0)) % 60,
		int(floor(time)) % 60,
		int(floor(time * 1000.0)) % 1000,
	]


func freeze_timer(val : bool = true) -> void:
	timer_frozen = val;

func set_timer(time: float) -> void:
	level_timer = time;

func timer_is_frozen() -> bool:
	return timer_frozen or level_state != level_states.RUNNING;

#endregion

#region score

var level_score_real : float = 0.
var level_score_display : float = 0.

enum {
	HIT_BY_PLAYER, 
	ENVIRONMENTAL_KILL
	}
	
func score_to_str(score: float = level_score_display) -> String:
	return "%08d" % score;

func reset_score() -> void:
	level_score_real = 0.
	level_score_display = 0.

func add_score(type : float, base_value : float, arguments : Dictionary = {}) -> void:
	
	var resulting_value = base_value;
	
	match type:
		HIT_BY_PLAYER:
			
			var bonus = []
			bonus.append(2.		if arguments.has("killed") 		and arguments["killed"] 	            else 0.);
			bonus.append(2. 	if arguments.has("enemy_airborne") 	and arguments["enemy_airborne"] 	else 0.);
			
			bonus.append(max(arguments["velocity"]/8 - 1., 0) if arguments.has("velocity") 	else 0.);
			
			var final_bonus := 1.;
			
			var rng = RandomNumberGenerator.new()
			var lol = rng.randi_range(0, 100)
			for b in bonus:
				final_bonus += b;
			
			resulting_value *= final_bonus;
			
			pass
			
		ENVIRONMENTAL_KILL:
			pass
	
	
	resulting_value = ceil(resulting_value / 5) * 5;
	level_score_real += resulting_value;
	
	pass;


func get_hit_score_arguments(killed : bool = false, velocity : float = 0., enemy_airborne : bool = false) -> Dictionary:
	return {
		"killed" : killed,
		"velocity" : velocity,
		"enemy_airborne" : enemy_airborne
	}
	
#endregion

#region Checkpoint System

var current_checkpoint_data : Dictionary = {};
func set_checkpoint(ent : LevelCheckpoint) -> void:
	
	if ent == null : 
		current_checkpoint_data = {};
		return;
	
	current_checkpoint_data = {
		"position" : ent.global_position,
		"rotation" : player.global_rotation,
		"score" : level_score_real
	}

func has_checkpoint() -> bool:
	return current_checkpoint_data.size() > 0;

func load_checkpoint(ent : CharacterBody3D = player) -> void:
	
	if !has_checkpoint():
		return;
	
	reset_level(false);
	player.position = current_checkpoint_data["position"]
	player.rotation = current_checkpoint_data["rotation"]
	level_score_real = current_checkpoint_data["score"]

func reset_level(reset_checkpoint : bool = true) -> void:

	if !current_level: return;
	
	current_level.reset_level();	
	if reset_checkpoint : 
		set_timer(0.0)
		reset_score();
		set_checkpoint(null)
		pro_gamer = true;
	
	freeze_player(false)
	freeze_timer(false)
	level_state = level_states.RUNNING;
	
#endregion

#region Gameplay Functions

var gameplay_HUD : CanvasLayer;

var player : CharacterBody3D;
var player_attack_origin : Node3D;
var player_camera : Camera3D;
var player_frozen : bool = false;

func freeze_player(val : bool = true) -> void:
	player_frozen = val;

func power_kick(height_bonus : float = 20., horizontal_min : float = 12., killed : bool = false, parry: bool = false) -> void:
	
	
	add_score(HIT_BY_PLAYER, 1000 if parry else 100, get_hit_score_arguments(killed, player.velocity.length(), true))
	
	var spd = MovementUtils.get_horizontal_vector(player.velocity).length();
	spd = max(spd * 1.6, horizontal_min);
	
	var dir = MovementUtils.get_look_direction_vector(player);
	dir.y = 0;
	
	player.velocity = dir * spd;
	player.velocity.y = abs(player.velocity.y) + height_bonus;
	
	GameJuice.hit_stop()
	GameJuice.hit_flash()
	GameJuice.shake_camera()

	player.health_component.set_invulnerability(0.1);
	player.telekinesis_component.set_cooldown(0);

#endregion

func freeze_game(freeze : bool = true) -> void:
	current_level.process_mode = Node.PROCESS_MODE_DISABLED if freeze else Node.PROCESS_MODE_INHERIT;


#region Player Death

const DEATH_SCREEN_HUD = preload("uid://cydh4023ioyj3")
var pro_gamer := true; #If true, the player has not died in this run.
#Is reset on a true reset_level()
func player_died() -> void:
	
	var death_screen_hud = DEATH_SCREEN_HUD.instantiate()
	get_tree().current_scene.add_child(death_screen_hud)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	freeze_game()
	freeze_timer()
	
	pro_gamer = false;
	
	level_state = level_states.DEAD;
	
	pass;
	
#endregion

#region Level End

const LEVEL_END_HUD = preload("uid://jyp8gah1vdiu")

func get_player_grade() -> String:
	
	var treshholds = current_level.get_grades();
	
	var time = level_timer - floor(level_score_real/1000);
	
	var grade = "F";
	var grade_val = INF; 
	for key in treshholds.keys():
		
		var this_grade_val = treshholds[key];
		if this_grade_val >= level_timer and this_grade_val < grade_val:
			grade = key;
			grade_val = treshholds[key];
	
	if grade == "S" and pro_gamer: 
		grade = "W";
		
	return grade;

func end_level() -> void:
	
	var level_end_hud = LEVEL_END_HUD.instantiate()
	get_tree().current_scene.add_child(level_end_hud)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	freeze_game();
	freeze_timer()
	
	level_state = level_states.END;
	
	level_end_hud.set_grade(get_player_grade());

	
	pass;

func player_is_crouched():
	return player.is_crouched;
#endregion

#region Pause Menu

const PAUSE_MENU_HUD = preload("uid://c6yh2pmnqapw0")
var pause_menu : CanvasLayer;

func game_is_paused() -> bool:
	return level_state == level_states.PAUSED;

func pause_game() -> void:
	
	if level_state == level_states.END or level_state == level_states.DEAD : return;
	
	pause_menu = PAUSE_MENU_HUD.instantiate()
	get_tree().current_scene.add_child(pause_menu)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	freeze_game();
	freeze_timer()
	
	level_state = level_states.PAUSED;

func unpause_game() -> void:
	
	if pause_menu == null : return;
	
	pause_menu.queue_free()
	freeze_game(false);
	freeze_timer(false)
	
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	level_state = level_states.RUNNING;
	pause_menu = null;

#endregion
