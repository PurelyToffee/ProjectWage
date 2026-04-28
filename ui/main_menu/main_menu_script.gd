extends Node
var current_state = LevelController.current_main_menu_state;
var levelsContainer: CenterContainer = null;
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	LevelController.level_state = LevelController.level_states.MAIN_MENU;
	if current_state == LevelController.mm_states.MAIN:
		levelsContainer = %LevelsCenterContainer;

func _input(event) -> void:
	if event.is_pressed():
		match current_state:
			LevelController.mm_states.SPLASH:
				LevelController.switch_main_menu_context(LevelController.mm_states.MAIN);
				
			LevelController.mm_states.MAIN:
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
	print("Byebye");
	get_tree().quit();

func _on_level_1_pressed() -> void:
	LevelController.play_tutorial();
	pass;

func _on_level_2_pressed() -> void:
	pass # Replace with function body.

func _on_level_3_pressed() -> void:
	pass # Replace with function body.
