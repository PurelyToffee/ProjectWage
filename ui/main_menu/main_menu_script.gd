extends Node

var current_state: LevelController.mm_states = LevelController.mm_states.SPLASH;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	LevelController.level_state = LevelController.level_states.MAIN_MENU;

func _input(event) -> void:
	if event is InputEventKey and event.is_pressed():
		var status: bool = \
			LevelController.switch_main_menu_context(LevelController.mm_states.MAIN, current_state);
		if status == true:
			current_state = LevelController.mm_states.MAIN;
			
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if current_state == LevelController.mm_states.SPLASH:
		_input(InputEventKey)
