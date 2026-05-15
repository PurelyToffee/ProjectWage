extends CanvasLayer
@onready var checkpoint: Button = %Checkpoint
@onready var settings_window: Window = %SettingsWindow
@onready var settings_scene: Control = %SettingsContainer
@onready var settings_back_button: Button = %SettingsBackButton


func _on_resume_pressed() -> void:
	
	LevelController.unpause_game()
	
	pass # Replace with function body.


func _on_checkpoint_pressed() -> void:
	
	LevelController.unpause_game()
	LevelController.load_checkpoint()
	
	pass # Replace with function body.


func _on_reset_pressed() -> void:
	
	LevelController.unpause_game()
	LevelController.reset_level()
	
	pass # Replace with function body.

func _on_settings_pressed() -> void:
	settings_scene.reset_state()
	settings_window.show()

func _on_return_to_menu_pressed() -> void:
	MenuController.return_to_main_menu()

func _on_ready() -> void:
	
	checkpoint.disabled = !LevelController.has_checkpoint();
	
	pass # Replace with function body.


func _on_settings_window_close_requested() -> void:
	settings_window.hide()

func _on_settings_back_button_pressed() -> void:
	if settings_scene._on_back_button_pressed():
		settings_window.hide()
