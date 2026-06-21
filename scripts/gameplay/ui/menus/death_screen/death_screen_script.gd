extends Node

@onready var checkpoint: Button = %Checkpoint

var confirm_dialog: ConfirmationDialog

func _ready() -> void:
	checkpoint.disabled = !LevelController.has_checkpoint()
	
	confirm_dialog = ConfirmationDialog.new()
	add_child(confirm_dialog)

func _on_checkpoint_pressed() -> void:
	LevelController.load_checkpoint()
	self.queue_free()
	#LevelController.close_menu()

func _on_restart_pressed() -> void:
	confirm_dialog.dialog_text = "Restart the level?"
	confirm_dialog.confirmed.connect(_confirm_restart, CONNECT_ONE_SHOT)
	confirm_dialog.popup_centered()

func _confirm_restart() -> void:
	LevelController.reset_level()
	self.queue_free()
	#LevelController.close_menu()
