extends Node

var player_frozen : bool = false;

var player : CharacterBody3D;
var player_attack_origin : Node3D;
var player_camera : Camera3D;
var level_timer : float = 0.0;
var timer_frozen : bool = false;

var hud : CanvasLayer;

const DualMacTen = preload("uid://bolqjo6l5kov7")

func time_to_str(time: float = level_timer):
	return "%02d:%02d:%03d" % [
		int(floor(time / 60.0)) % 60,
		int(floor(time)) % 60,
		int(floor(time * 1000.0)) % 1000,
	]

func _process(delta : float) -> void:
	if !timer_frozen:
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
	timer_frozen = false
	set_timer(0.0)
	

#endregion


#region Level End

const LEVEL_END_HUD = preload("uid://wn6yibaf2gfb")
func end_level() -> void:
	
	var hud = LEVEL_END_HUD.instantiate()
	get_tree().current_scene.add_child(hud)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	freeze_player(true)
	timer_frozen = true
	
	pass;

func set_timer(time: float) -> void:
	level_timer = time

func freeze_timer(val: bool) -> void:
	timer_frozen = val

func player_is_crouched():
	return player.is_crouched;
#endregion
