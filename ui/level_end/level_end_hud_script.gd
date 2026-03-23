extends CanvasLayer

@onready var time_taken : Label = %TimeTaken;

func _ready() -> void:
	time_taken.text = LevelController.time_to_str()

func _on_button_pressed() -> void:
	
	LevelController.reset_level();
	self.queue_free()
