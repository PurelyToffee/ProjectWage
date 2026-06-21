class_name ExtrasButton extends PanelContainer

signal pressed;

@onready var color_rect: ColorRect = %ColorRect
@export var screen : MenuScreen;


func _process(delta: float) -> void:
	if color_rect.color != Color("EF9849ff"): 
		color_rect.color = Color("9D312Fff") if (screen.selected == self) else Color("161616ff")

func _on_button_pressed() -> void:
	pressed.emit();


func _on_button_mouse_entered() -> void:
	
	color_rect.color = Color("EF9849ff")
	
	pass # Replace with function body.


func _on_button_mouse_exited() -> void:
	
	color_rect.color = Color("161616ff")
	
	pass # Replace with function body.
