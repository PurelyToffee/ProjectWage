class_name MainMenu extends CanvasLayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
		
	MenuController.main_menu = self;

func _input(event: InputEvent):
	match MenuController.current_main_menu_state:
		MenuController.mn_states.SPLASH:
			if event is not InputEventMouseMotion:
				MenuController.switch_main_menu_context(MenuController.mn_states.MAIN)
		MenuController.mn_states.MAIN:
			if InputController.escape():
				MenuController.go_back()
