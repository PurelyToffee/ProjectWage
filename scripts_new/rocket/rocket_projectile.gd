extends RigidBody3D

@export var explosion_scene: PackedScene

@export var speed := 40.0


func _ready():
	linear_velocity = -transform.basis.z * (maxf(LevelController.player.velocity.length() + 8. , speed))


func _on_body_entered(body: Node) -> void:
	
	var rocket = explosion_scene.instantiate()
	rocket.global_position = global_position
	get_tree().current_scene.add_child(rocket)
	
	queue_free()
