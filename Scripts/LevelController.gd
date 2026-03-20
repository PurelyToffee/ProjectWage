extends Node

var player_frozen : bool = false;

var player : CharacterBody3D;
var player_attack_origin : Node3D;
var player_camera : Camera3D;
var level_timer : float;

var hud : CanvasLayer;

const DualMacTen = preload("uid://bolqjo6l5kov7")

func time_to_str(time: float = level_timer):
	# var hours: String = str(floor(time / (60*60)))
	var minutes: String = str(int(floor(time / 60.0)) % 60)
	var seconds: String = str(int(floor(time)) % 60)
	var millis: String = str(int(floor(time * 1000.0)) % 1000)
	if minutes.length() < 2:
		minutes = "0" + minutes
	if seconds.length() < 2:
		seconds = "0" + seconds
	if millis.length() < 3:
		millis = "0" + millis
		if millis.length() < 3:
			millis = "0" + millis
	return minutes + ":" + seconds + ":" + millis

func _process(delta : float) -> void:
	level_timer += delta;
	if Input.is_action_just_pressed("launch_enemy"):
		load_checkpoint()

func freeze_player(val : bool) -> void:
	player_frozen = val;


#region Checkpoint System

var current_checkpoint : LevelCheckpoint;
func set_checkpoint(ent : LevelCheckpoint) -> void:
	
	current_checkpoint = ent;

func load_checkpoint(ent : CharacterBody3D = player) -> void:
	
	if !current_checkpoint:
		return;
		
	current_checkpoint.respawn_entity(ent);

func reset_level() -> void:
	get_tree().reload_current_scene();
	set_checkpoint(null)
	
	freeze_player(false)
	

#endregion


#region Level End

const LEVEL_END_HUD = preload("uid://wn6yibaf2gfb")
func end_level() -> void:
	
	var hud = LEVEL_END_HUD.instantiate()
	get_tree().current_scene.add_child(hud)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	freeze_player(true)
	
	pass;

func player_is_crouched():
	return player.is_crouched;
#endregion
