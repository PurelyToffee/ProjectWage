extends Node

@onready var sub_viewport_container: SubViewportContainer = %SubViewportContainer

func ready() -> void:
	LevelController.current_level = self;
