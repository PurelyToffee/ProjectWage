class_name PlayerRocket extends RocketParent

@export var explosion_scene: PackedScene

func _on_body_entered(body: Node) -> void:
	
	var rocket = explosion_scene.instantiate()
	rocket.global_position = global_position
	get_tree().current_scene.add_child(rocket)
	
	queue_free()
