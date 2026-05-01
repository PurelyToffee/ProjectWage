class_name MainScene extends Node3D

@onready var main_menu: CanvasLayer = %MainMenu

func _ready() -> void:
	MainController.main_scene = self;
