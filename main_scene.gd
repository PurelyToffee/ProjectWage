class_name MainScene extends Node3D

const MAIN_GAMEPLAY = preload("uid://cquoylggpj31s")

func _ready() -> void:
	MainController.main_scene = self;
