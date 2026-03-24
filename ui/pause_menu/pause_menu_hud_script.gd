extends Node
@onready var checkpoint: Button = %Checkpoint


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


func _on_ready() -> void:
	
	checkpoint.disabled = !LevelController.has_checkpoint();
	
	pass # Replace with function body.
