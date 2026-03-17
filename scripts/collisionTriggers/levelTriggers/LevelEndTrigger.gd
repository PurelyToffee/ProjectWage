extends CollisionTrigger


func trigger(body) -> void:
	
	if !active : return;
	if !body.is_in_group("player") : return;
	
	LevelController.end_level();
	set_active(false)
