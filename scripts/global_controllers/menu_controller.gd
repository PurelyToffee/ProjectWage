extends Node

const MAIN_GAMEPLAY_SCENE = preload("uid://cquoylggpj31s")

enum mn_states {
	SPLASH,
	MAIN,
	SETTINGS,
}

const SPLASH_SCREEN_MENU = preload("uid://dsgdyoioeke0c")
const MAIN_MENU = preload("uid://djt75dcs135ms")

var current_main_menu_state: mn_states = mn_states.SPLASH;

var main_menu : MainMenu;

func game_is_in_main_menu() -> bool:
	return current_main_menu_state == mn_states.MAIN;

func enter_splash_screen() -> void:
	current_main_menu_state = mn_states.SPLASH;
	change_menu(SPLASH_SCREEN_MENU)
	
func enter_main_menu() -> void:
	current_main_menu_state = mn_states.MAIN;
	change_menu(MAIN_MENU)

func change_menu(menu : PackedScene) -> void:
	
	for child in main_menu.get_children():
		child.queue_free();
		
	main_menu.add_child(menu.instantiate())

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
	
	MainController.set_level(TUTORIAL_LEVEL)
	
	pass;
	# TODO: handle level selection
	
func play_level1() -> void:
	pass;
	# TODO: yada yada


func quit() -> void:
	main_menu.hide() # does this do anything?
	MainController.set_game_state(MainController.game_states.on_level)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func return_to_main_menu() -> void:
	MainController.quit_level()
	MainController.set_game_state(MainController.game_states.main_menu)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	main_menu.show()
	main_menu.get_child(0).return_to_main_menu() # I Just Made Some BULLLLLLSHITTTTT!!!!!!
