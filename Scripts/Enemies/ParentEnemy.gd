class_name ParentEnemy extends CharacterBody3D

@export var enemy_groups: Array[String] = []

func _ready() -> void:
	
	add_to_group("enemy")
	
	for group in enemy_groups:
		add_to_group(group)
		

func on_triggered() -> void:
	pass
