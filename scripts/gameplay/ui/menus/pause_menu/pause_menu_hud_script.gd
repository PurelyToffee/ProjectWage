extends CanvasLayer

@onready var checkpoint: Button = %Checkpoint
@onready var settings_window: Window = %SettingsWindow
@onready var settings_scene: Control = %SettingsContainer
@onready var settings_back_button: Button = %SettingsBackButton

var settings_open: bool = false
var confirm_dialog: ConfirmationDialog

func _ready() -> void:
	checkpoint.disabled = !LevelController.has_checkpoint()
	
	confirm_dialog = ConfirmationDialog.new()
	add_child(confirm_dialog)

func _on_resume_pressed() -> void:
	LevelController.unpause_game()

func _on_checkpoint_pressed() -> void:
	confirm_dialog.dialog_text = "Return to checkpoint?"
	confirm_dialog.confirmed.connect(_confirm_checkpoint, CONNECT_ONE_SHOT)
	confirm_dialog.popup_centered()

func _confirm_checkpoint() -> void:
	LevelController.unpause_game()
	LevelController.load_checkpoint()

func _on_reset_pressed() -> void:
	confirm_dialog.dialog_text = "Restart the level?"
	confirm_dialog.confirmed.connect(_confirm_reset, CONNECT_ONE_SHOT)
	confirm_dialog.popup_centered()

func _confirm_reset() -> void:
	LevelController.unpause_game()
	LevelController.reset_level()

func _on_settings_pressed() -> void:
	settings_scene.reset_state()
	settings_window.show()
	settings_open = true

func _on_return_to_menu_pressed() -> void:
	confirm_dialog.dialog_text = "Return to main menu?"
	confirm_dialog.confirmed.connect(_confirm_return_to_menu, CONNECT_ONE_SHOT)
	confirm_dialog.popup_centered()

func _confirm_return_to_menu() -> void:
	MenuController.return_to_main_menu()

func _on_settings_window_close_requested() -> void:
	close_settings()

func close_settings() -> void:
	settings_window.hide()
	settings_open = false

func _on_settings_back_button_pressed() -> void:
	# go_back() returns true if it stepped out of a sub-menu internally (stay
	# open); false if already at the top settings menu (close the window).
	if !settings_scene.go_back():
		close_settings()
