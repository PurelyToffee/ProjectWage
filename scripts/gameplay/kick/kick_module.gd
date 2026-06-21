class_name KickModule extends Node

@export var kick_scene: PackedScene;
var max_delay := 0.1;
var delay := 0.;

func _process(delta: float) -> void:
	delay = max(delay - delta, 0);

func kick() -> void:
	
	if delay > 0.: return;
	
	var kick_instance = kick_scene.instantiate()
	kick_instance.global_transform = LevelController.player_attack_origin.global_transform
	get_tree().current_scene.add_child(kick_instance)
	
	delay = max_delay;
	InputController.reset_kick_buffer();
	
	pass
