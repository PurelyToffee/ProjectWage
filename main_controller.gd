extends Node

var main_scene : MainScene;


func instantiate_scene(scene : PackedScene) -> void:
	
	var scn = scene.instantiate();
	main_scene.add_child(scn);
