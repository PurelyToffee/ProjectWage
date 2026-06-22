extends Node

var main_menu : Control;

func close() -> void:
	main_menu.hide() # does this do anything?
	GameController.set_game_state(GameController.game_states.on_level)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func return_to_main_menu() -> void:
	
	LevelController.set_checkpoint(null);
	LevelController.close_menu();
	
	GameController.quit_level()
	GameController.set_game_state(GameController.game_states.main_menu)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	
	main_menu.show()
