extends Node3D

var current_level : Node3D;
var gameplay_viewport_container : SubViewportContainer;

var level_state : int = level_states.RUNNING;
enum level_states {
	START,
	RUNNING,
	END,
	DEAD
}

#region Weapons

const DualMacTen = preload("uid://bolqjo6l5kov7")

#endregion

func _process(delta : float) -> void:
	if !timer_is_frozen(): level_timer += delta;
	if Input.is_action_just_pressed("launch_enemy"):
		load_checkpoint()

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
	
	reset_level(false);
	current_checkpoint.respawn_entity(player)

func reset_level(reset_checkpoint : bool = true) -> void:

	if !current_level: return;
	
	current_level.reset_level();	
	if reset_checkpoint : set_checkpoint(null)
	
	freeze_player(false)
	freeze_timer(false)
	set_timer(0.0)
	
#endregion

#region Gameplay Functions

var gameplay_HUD : CanvasLayer;

var player : CharacterBody3D;
var player_attack_origin : Node3D;
var player_camera : Camera3D;
var player_frozen : bool = false;

func freeze_player(val : bool = true) -> void:
	player_frozen = val;

#endregion


#region Level End

const LEVEL_END_HUD = preload("uid://jyp8gah1vdiu")

func end_level() -> void:
	
	var hud = LEVEL_END_HUD.instantiate()
	get_tree().current_scene.add_child(hud)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	freeze_player(true)
	timer_frozen = true
	
	pass;

func player_is_crouched():
	return player.is_crouched;
#endregion
