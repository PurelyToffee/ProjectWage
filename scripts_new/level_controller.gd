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

func add_score(type, base_value : float, arguments : Dictionary = {}) -> void:
	
	var resulting_value = base_value;
	
	match type:
		HIT_BY_PLAYER:
			
			var bonus = []
			bonus.append(3		if arguments.has("headshot") 	and arguments["headshot"] 	else 0.);
			bonus.append(2.		if arguments.has("killed") 		and arguments["killed"] 	else 0.);
			bonus.append(2. 	if arguments.has("airborne") 	and arguments["airborne"] 	else 0.);
			bonus.append(10. 	if arguments.has("parry") 	    and arguments["parry"] 	else 0.);
			
			bonus.append(max(arguments["velocity"]/8 - 1., 0) if arguments.has("velocity") 	else 0.);
			
			var final_bonus := 1.;
			
			var rng = RandomNumberGenerator.new()
			var lol = rng.randi_range(0, 100)
			for b in bonus:
				print("%s %s" % [b, lol])
				final_bonus += b;
			
			resulting_value *= final_bonus;
			
			pass
			
		ENVIRONMENTAL_KILL:
			pass
	
	level_score_real += resulting_value;
	
	pass;


func get_hit_score_arguments(headshot : bool = false, killed : bool = false, 
								velocity : float = 0., airborne : bool = false, parry : bool = false) -> Dictionary:
	return {
		"headshot" : headshot,
		"killed" : killed,
		"velocity" : velocity,
		"airborne" : airborne,
		"parry" : parry,
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
	
	await reset_level(true);
	player.position = current_checkpoint_data["position"]
	player.rotation = current_checkpoint_data["rotation"]
	level_score_real = current_checkpoint_data["score"]

func reset_level(checkpoint_reset : bool = false) -> void:

	if !current_level: return;
	
	current_level.reset_level();	
	if !checkpoint_reset : 
		set_timer(0.0)
		reset_score();
		set_checkpoint(null)
	
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
	
	
	
	add_score(HIT_BY_PLAYER, 100, get_hit_score_arguments(false, killed, player.velocity.length(), true, parry))
	
	var spd = MovementUtils.get_horizontal_vector(player.velocity).length();
	spd = max(spd * 1.6, horizontal_min);
	
	var dir = MovementUtils.get_look_direction_vector(player);
	dir.y = 0;
	
	player.velocity = dir * spd;
	player.velocity.y = abs(player.velocity.y) + height_bonus;
	
	GameJuice.hit_stop()
	GameJuice.hit_flash()
	GameJuice.shake_camera()

#endregion

func freeze_game(freeze : bool = true) -> void:
	current_level.process_mode = Node.PROCESS_MODE_DISABLED if freeze else Node.PROCESS_MODE_INHERIT;


#region Player Death

const DEATH_SCREEN_HUD = preload("uid://cydh4023ioyj3")
func player_died() -> void:
	
	var death_screen_hud = DEATH_SCREEN_HUD.instantiate()
	get_tree().current_scene.add_child(death_screen_hud)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	freeze_game()
	freeze_timer()
	
	level_state = level_states.DEAD;
	
	pass;
	
#endregion

#region Level End

const LEVEL_END_HUD = preload("uid://jyp8gah1vdiu")

func end_level() -> void:
	
	var level_end_hud = LEVEL_END_HUD.instantiate()
	get_tree().current_scene.add_child(level_end_hud)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	freeze_game();
	freeze_timer()
	
	level_state = level_states.END;
	
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
