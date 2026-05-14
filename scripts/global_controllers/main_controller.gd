extends Node

var main_scene : MainScene;
var main_gameplay : MainGameplay;
const MAIN_GAMEPLAY = preload("uid://cquoylggpj31s")

enum game_states{
	main_menu,
	on_level
}
var game_state := game_states.main_menu;


func instantiate_scene(scene : PackedScene):
	
	var scn = scene.instantiate();
	main_scene.add_child(scn);

	return scn;

func set_level(level : PackedScene) -> void:
	
	if main_gameplay : main_gameplay.queue_free();
	main_gameplay = instantiate_scene(MAIN_GAMEPLAY);
	
	main_gameplay.set_level(level);
	
func set_game_state(val : game_states) -> void:
	game_state = val;

func get_game_state() -> game_states:
	return game_state;
