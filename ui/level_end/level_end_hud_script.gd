extends CanvasLayer

@onready var time_taken : Label = %TimeTaken;
@onready var grade: Label = %Grade

func _ready() -> void:
	time_taken.text = LevelController.time_to_str()

func _on_button_pressed() -> void:
	
	LevelController.reset_level();
	self.queue_free()
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func set_grade(val : String) -> void:
	grade.text = val;
	
	if val == "W":
		grade.label_settings.font_color = Color(1, 0, 0);
