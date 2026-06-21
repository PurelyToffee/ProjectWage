extends PanelContainer

@onready var label: Label = %Label
@onready var button: Button = %Button

@export var link : String = ""

func _ready() -> void:
	_on_button_mouse_exited()

func reset_button() -> void:
	label.modulate = Color("999999ff");
	button.mouse_default_cursor_shape = Control.CURSOR_ARROW

func _on_button_mouse_entered() -> void:
	
	if link == "" : 
		reset_button()
		return;

	label.modulate = Color("EF9849ff")
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	pass # Replace with function body.


func _on_button_mouse_exited() -> void:
	
	
	if link == "" : 
		reset_button()
		return;
	
	label.modulate = Color("9D312Fff")
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	pass # Replace with function body.


func _on_button_pressed() -> void:
	if link != "" : OS.shell_open(link)
