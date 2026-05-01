extends Node

const MAIN_GAMEPLAY_SCENE = preload("uid://cquoylggpj31s")

enum mn_states {
	SPLASH,
	MAIN,
	SETTINGS,
}
const START_SPLASH = preload("uid://scrjr1okshra")
const MAIN_MENU = preload("uid://xh6aig0yqpjm")

var current_main_menu_state: mn_states = mn_states.SPLASH;

var main_menu : MainMenu;

func game_is_in_main_menu() -> bool:
	return current_main_menu_state == mn_states.MAIN;

func enter_splash_screen() -> void:
	current_main_menu_state = mn_states.SPLASH;
	main_menu.change_scene_to_packed(START_SPLASH);
	
func enter_main_menu() -> void:
	current_main_menu_state = mn_states.MAIN;
	main_menu.change_scene_to_packed(MAIN_MENU);

func switch_main_menu_context(next) -> bool:
	match next:
		mn_states.SPLASH:
			if current_main_menu_state == mn_states.SPLASH:
				return false;
			else:
				enter_splash_screen();
				return true;
		mn_states.MAIN:
			if current_main_menu_state == mn_states.MAIN:
				return false;
			else:
				enter_main_menu();
				return true;
		_:
			return false;

const TUTORIAL_LEVEL = preload("uid://dpkbh0ntnudvo")

func play_tutorial() -> void:
	
	MainController.instantiate_scene(TUTORIAL_LEVEL)
	
	pass;
	# TODO: handle level selection
	
func play_level1() -> void:
	pass;
	# TODO: yada yada


func quit() -> void:
	
	main_menu.hide();
