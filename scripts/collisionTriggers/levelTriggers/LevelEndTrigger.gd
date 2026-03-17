extends CollisionTrigger


func trigger(body) -> void:
	
	super.trigger(body);
	if !body.is_in_group("player") : return;
	
	LevelController.end_level();
	set_active(false)
