class_name MainMenu extends CanvasLayer
var current_state = MenuController.current_main_menu_state;
var levelsContainer: CenterContainer = null;


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if current_state == MenuController.mn_states.MAIN:
		levelsContainer = %LevelsCenterContainer;
		
		
	MenuController.main_menu = self;

func _input(event) -> void:
	if event.is_pressed():
		match current_state:
			MenuController.mn_states.SPLASH:
				MenuController.switch_main_menu_context(MenuController.mn_states.MAIN);
				
			MenuController.mn_states.MAIN:
				var levelContainer = %LevelsCenterContainer;
				if event.is_action("escape"):
					levelContainer.hide();
			_:
				pass;
		
			
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass;
	
func _on_play_pressed() -> void:
	levelsContainer.show();

func _on_settings_pressed() -> void:
	pass # Replace with function body.

func _on_quit_pressed() -> void:
	get_tree().quit();

func _on_tutorial_pressed() -> void:
	MenuController.play_tutorial();
	
	MenuController.quit()
	
	pass;

func _on_level_1_pressed() -> void:
	pass # Replace with function body.

func _on_level_2_pressed() -> void:
	pass # Replace with function body.
