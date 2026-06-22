extends Node

@onready var checkpoint: Button = %Checkpoint

func _ready() -> void:
	checkpoint.disabled = !LevelController.has_checkpoint()


func _on_checkpoint_pressed() -> void:
	LevelController.load_checkpoint()
	self.queue_free()
	#LevelController.close_menu()

func _on_restart_pressed() -> void:
	
	GameController.confirm_popup("Restart the level?", _confirm_restart)


func _confirm_restart() -> void:
	LevelController.reset_level()
	self.queue_free()
	#LevelController.close_menu()
