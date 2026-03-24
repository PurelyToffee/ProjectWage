extends Node

@onready var checkpoint: Button = %Checkpoint

func _on_ready() -> void:
	
	checkpoint.disabled = !LevelController.has_checkpoint();



func _on_checkpoint_pressed() -> void:
	
	LevelController.load_checkpoint();
	self.queue_free();
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	pass # Replace with function body.


func _on_restart_pressed() -> void:
	
	LevelController.reset_level();
	self.queue_free();
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	pass # Replace with function body.
