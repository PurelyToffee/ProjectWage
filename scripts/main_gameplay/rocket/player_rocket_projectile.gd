class_name PlayerRocket extends ProjectileParent

@export var explosion_scene: PackedScene

func _on_body_entered(body: Node) -> void:
	
	var rocket = explosion_scene.instantiate()
	rocket.global_position = global_position
	get_tree().current_scene.add_child(rocket)
	
	queue_free()


func _on_area_3d_body_entered(body: Node3D) -> void:
	pass # Replace with function body.
