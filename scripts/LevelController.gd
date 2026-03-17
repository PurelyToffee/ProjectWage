extends Node

var player_frozen : bool = false;

var player : CharacterBody3D;
var player_attack_origin : Node3D;
var player_camera : Camera3D;

var hud : CanvasLayer;

const DualMacTen = preload("uid://bolqjo6l5kov7")

func _process(delta : float) -> void:
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


#endregion
