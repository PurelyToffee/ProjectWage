extends Node

var main_menu : MainMenu;

func close() -> void:
	main_menu.hide() # does this do anything?
	MainController.set_game_state(MainController.game_states.on_level)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func return_to_main_menu() -> void:
	LevelController.set_checkpoint(null);
	MainController.quit_level()
	MainController.set_game_state(MainController.game_states.main_menu)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	main_menu.show()
