extends Control

@export var title : String = ""
@export var description : String = ""

@onready var popup: Control = %Popup

@onready var name_label : Label = %Name
@onready var time_label : Label = %Time

func _ready() -> void:
	name_label.text = title;
	time_label.text = description;


func _on_button_mouse_entered() -> void:
	
	popup.show();
	
	pass # Replace with function body.


func _on_button_mouse_exited() -> void:
	
	popup.hide();
	
	pass # Replace with function body.
