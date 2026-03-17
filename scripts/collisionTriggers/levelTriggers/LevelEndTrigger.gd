extends CollisionTrigger


func trigger(body) -> void:
	
	super.trigger(body);
	
	LevelController.end_level();
	set_active(false)
