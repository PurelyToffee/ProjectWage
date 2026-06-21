extends PanelContainer

@onready var label: Label = %Label
@onready var button: Button = %Button

signal pressed;

func _on_button_pressed() -> void:
	pressed.emit();


func _on_button_mouse_entered() -> void:
	
	label.modulate = Color("EF9849ff")
	
	pass # Replace with function body.


func _on_button_mouse_exited() -> void:
	
	label.modulate = Color("999999ff")
	
	pass # Replace with function body.
