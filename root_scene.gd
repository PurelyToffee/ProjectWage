class_name MainScene extends Node3D

@onready var main_menu: CanvasLayer = %MainMenu
@onready var gameplay_node: Node3D = %GameplayNode


func _ready() -> void:
	GameController.main_scene = self;
