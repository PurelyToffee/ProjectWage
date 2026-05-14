class_name MainMenu extends CanvasLayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
		
	MenuController.main_menu = self;

			
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	match MenuController.current_main_menu_state:
		
		MenuController.mn_states.SPLASH:
			if InputController.any():
				MenuController.switch_main_menu_context(MenuController.mn_states.MAIN);
				
		MenuController.mn_states.MAIN:
			
			if InputController.escape():
				get_child(0).levels_container.hide();
	
