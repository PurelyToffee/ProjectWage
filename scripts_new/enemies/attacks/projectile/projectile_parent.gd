class_name RocketParent extends RigidBody3D

@export var speed := 40.0

func _ready():
	set_speed();
	
func set_speed() -> void:
	linear_velocity = -transform.basis.z * (maxf(LevelController.player.velocity.length() + 8. , speed))



func _on_body_entered(body: Node) -> void:
	
	queue_free();
