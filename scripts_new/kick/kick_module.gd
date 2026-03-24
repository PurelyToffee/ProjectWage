class_name KickModule extends Node

@export var kick_scene: PackedScene;

func kick() -> void:
	
	var rocket = kick_scene.instantiate()
	rocket.global_transform = LevelController.player_attack_origin.global_transform
	get_tree().current_scene.add_child(rocket)
	
	pass
