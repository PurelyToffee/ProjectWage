extends Node

var main_scene : MainScene;
var main_gameplay : MainGameplay;
const MAIN_GAMEPLAY = preload("uid://cquoylggpj31s")

func instantiate_scene(scene : PackedScene):
	
	var scn = scene.instantiate();
	main_scene.add_child(scn);

	return scn;

func set_level(level : PackedScene) -> void:
	
	if main_gameplay : main_gameplay.queue_free();
	main_gameplay = instantiate_scene(MAIN_GAMEPLAY);
	
	main_gameplay.set_level(level);
	
