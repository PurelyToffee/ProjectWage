class_name PlayerRocket extends ProjectileParent

@export var explosion_scene: PackedScene

# explode on any contact (wall, enemy, anything).
func _handle_body_contact(_body: Node) -> bool:
	var explosion = explosion_scene.instantiate()
	explosion.global_position = global_position
	get_tree().current_scene.add_child(explosion)
	return true

func _on_area_3d_body_entered(_body: Node3D) -> void:
	pass
