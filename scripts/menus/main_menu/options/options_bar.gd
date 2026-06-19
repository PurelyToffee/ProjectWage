extends Control

@onready var margin_container: MarginContainer = %MarginContainer
var options_size : Vector2;

func _ready() -> void:
	options_size = margin_container.size
