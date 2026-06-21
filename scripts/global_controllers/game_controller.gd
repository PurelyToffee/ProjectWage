extends Node

var main_scene : MainScene;
var main_gameplay : MainGameplay;
var main_hud : MainMenuCanvas;

var MAIN_GAMEPLAY = load("uid://cquoylggpj31s")

const CONFIRMATION_POPUP = preload("uid://i6yn7lg2oy8j")
var loading_screen : LoadingScreen;

enum game_states{
	main_menu,
	on_level
}
var game_state := game_states.main_menu;

func in_main_menu() -> bool:
	return game_state == game_states.main_menu;

func instantiate_scene(scene : PackedScene):
	
	var scn = scene.instantiate();
	main_scene.gameplay_node.add_child(scn);
	
	return scn;
	
func instantiate_scene_HUD(scene : PackedScene):
	
	var scn = scene.instantiate();
	main_hud.add_child(scn);
	
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


func confirm_popup(text : String, confirm, cancel = null) -> ConfirmationPopup:
	var scene : ConfirmationPopup = instantiate_scene_HUD(CONFIRMATION_POPUP)
	scene.set_description(text);
	scene.set_confirmation(confirm);
	if cancel != null: scene.set_cancel(cancel);
	
	return scene;

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
