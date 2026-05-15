extends Node

var main_scene : MainScene;
var main_gameplay : MainGameplay;
var MAIN_GAMEPLAY = load("uid://cquoylggpj31s")


var tutorials_enabled := true;

var settings := {
	"tutorialsEnabled" : true,
}

enum game_states{
	main_menu,
	on_level
}
var game_state := game_states.main_menu;


func _ready():
	print(MAIN_GAMEPLAY)
	print(MAIN_GAMEPLAY.get_state().get_node_count())

func is_tutorial_enabled() -> bool:
	return settings.tutorialsEnabled;
	
func set_tutorial_enabled(val : bool) -> void:
	settings.tutorialsEnabled = val;

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

func quit_level() -> void:
	if main_gameplay : main_gameplay.queue_free()
	main_gameplay = null
