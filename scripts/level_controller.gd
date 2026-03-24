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

#region Checkpoint System

var current_checkpoint : LevelCheckpoint;
func set_checkpoint(ent : LevelCheckpoint) -> void:
	
	current_checkpoint = ent;

func load_checkpoint(ent : CharacterBody3D = player) -> void:
	
	if !current_checkpoint:
		return;
	
	reset_level(true);
	current_checkpoint.respawn_entity(player)

func reset_level(checkpoint_reset : bool = false) -> void:

	if !current_level: return;
	
	current_level.reset_level();	
	if !checkpoint_reset : 
		set_timer(0.0)
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

func power_kick(height_bonus : float = 24.) -> void:
	player.velocity.y = abs(player.velocity.y) + height_bonus;
	GameJuice.hit_stop()
	GameJuice.hit_flash()
	GameJuice.shake_camera()

#endregion

func freeze_game(freeze : bool = true) -> void:
	current_level.process_mode = Node.PROCESS_MODE_DISABLED if freeze else Node.PROCESS_MODE_INHERIT;


#region Level End

const LEVEL_END_HUD = preload("uid://jyp8gah1vdiu")

func end_level() -> void:
	
	var hud = LEVEL_END_HUD.instantiate()
	get_tree().current_scene.add_child(hud)
	
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
	
	level_state = level_states.RUNNING;
	pause_menu = null;

#endregion
