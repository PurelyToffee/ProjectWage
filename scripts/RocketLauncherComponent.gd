class_name RocketLauncherComponent extends Node

@export var rocket_scene: PackedScene

const MAX_ROCKETS := 4;
var rockets = MAX_ROCKETS;

var rockets_reload_speed = 0.5;


func update(delta : float) -> void:
	
	rockets = clamp(rockets + rockets_reload_speed * delta, 0, MAX_ROCKETS)

func launch_rocket() -> void:
	
	if floor(rockets) < 1: return;
	rockets -= 1;
	
	var rocket = rocket_scene.instantiate()
	rocket.global_transform = LevelController.player_attack_origin.global_transform
	get_tree().current_scene.add_child(rocket)
	
	pass
