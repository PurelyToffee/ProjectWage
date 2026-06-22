extends CanvasLayer

@onready var checkpoint: Button = %Checkpoint
@onready var settings_window: Window = %SettingsWindow
@onready var settings_scene: Control = %SettingsContainer
@onready var settings_back_button: Button = %SettingsBackButton

var settings_open: bool = false

func _ready() -> void:
	checkpoint.disabled = !LevelController.has_checkpoint()

func _on_resume_pressed() -> void:
	LevelController.unpause_game()

func _on_checkpoint_pressed() -> void:
	
	
	GameController.confirm_popup("Return to checkpoint?", _confirm_checkpoint)
	

func _confirm_checkpoint() -> void:
	LevelController.unpause_game()
	LevelController.load_checkpoint()

func _on_reset_pressed() -> void:
	
	GameController.confirm_popup("Restart the level?", _confirm_reset)

func _confirm_reset() -> void:
	LevelController.unpause_game()
	LevelController.reset_level()

func _on_settings_pressed() -> void:
	settings_scene.reset_state()
	settings_window.show()
	settings_open = true

func _on_return_to_menu_pressed() -> void:
	
	GameController.confirm_popup("Return to main menu?", _confirm_return_to_menu)

func _confirm_return_to_menu() -> void:
	MenuController.return_to_main_menu()

func _on_settings_window_close_requested() -> void:
	close_settings()

func close_settings() -> void:
	settings_window.hide()
	settings_open = false

func _on_settings_back_button_pressed() -> void:
	if !settings_scene.go_back():
		close_settings()
