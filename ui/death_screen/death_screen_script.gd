extends Node

@onready var checkpoint: Button = %Checkpoint

func _on_ready() -> void:
	
	if LevelController.current_checkpoint == null:
		checkpoint.disabled = true;



func _on_checkpoint_pressed() -> void:
	
	LevelController.load_checkpoint();
	self.queue_free();
	
	pass # Replace with function body.


func _on_restart_pressed() -> void:
	
	LevelController.reset_level();
	self.queue_free();
	pass # Replace with function body.
