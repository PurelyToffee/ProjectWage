extends RocketParent

@export var damage := 15.0;

func _on_body_entered(body: Node) -> void:
	
	if body.is_in_group("player"):
		LevelController.player.take_damage(damage)
		
	queue_free();
