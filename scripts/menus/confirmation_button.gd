class_name ConfirmationButton extends PanelContainer

signal pressed;

@onready var color_rect: ColorRect = %ColorRect

func _on_button_pressed() -> void:
	pressed.emit();


func _on_button_mouse_entered() -> void:
	
	color_rect.color = Color("9D312Fff")
	
	pass # Replace with function body.


func _on_button_mouse_exited() -> void:
	
	color_rect.color = Color("161616ff")
	
	pass # Replace with function body.
