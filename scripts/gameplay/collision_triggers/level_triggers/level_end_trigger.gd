extends CollisionTrigger


func _ready() -> void:
	super._ready()
	visible = true;

func trigger(body) -> void:
	
	if !active : return;
	if !body.is_in_group("player") : return;
	
	LevelController.end_level();
	set_active(false)
