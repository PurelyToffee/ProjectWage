class_name MainMenu extends CanvasLayer
var current_state = MenuController.current_main_menu_state;


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
		
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
