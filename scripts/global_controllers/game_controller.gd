extends Node

var main_scene : MainScene;
var main_gameplay : MainGameplay;
var MAIN_GAMEPLAY = load("uid://cquoylggpj31s")

enum game_states{
	main_menu,
	on_level
}
var game_state := game_states.main_menu;

func in_main_menu() -> bool:
	return game_state == game_states.main_menu;

func instantiate_scene(scene : PackedScene):
	
	var scn = scene.instantiate();
	main_scene.add_child(scn);
	
	return scn;

const TUTORIAL_LEVEL = "uid://dpkbh0ntnudvo"

enum LEVELS {
	tutorial,
	whiskeyWhiskers,
	FloorWater
}

# not an array because ID matters
var levels = {
	LEVELS.tutorial: {
		"name": "Tutorial",
		"scene_path": TUTORIAL_LEVEL,
	},
	LEVELS.whiskeyWhiskers: {
		"name": "Whiskey & Whiskers",
		"scene_path": null,
	},
	LEVELS.FloorWater: {
		"name": "The Floor is Water",
		"scene_path": null,
	},
}

func load_level(level_id: int, scene: PackedScene) -> void:
	if main_gameplay : main_gameplay.queue_free();
	main_gameplay = instantiate_scene(MAIN_GAMEPLAY);
	main_gameplay.load_level(scene);
	
	MenuController.close();
	
func set_game_state(val : game_states) -> void:
	game_state = val;

func get_game_state() -> game_states:
	return game_state;

func quit_level() -> void:
	if main_gameplay : main_gameplay.queue_free()
	main_gameplay = null
