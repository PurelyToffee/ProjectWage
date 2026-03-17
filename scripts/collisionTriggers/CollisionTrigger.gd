class_name CollisionTrigger extends Node

var active := true;

func trigger() -> void:
	
	if !active : return;
	
	print("Collided with %s" % self)
	
func set_active(val : bool) -> void:
	active = val;
	
func get_active() -> bool:
	return active;
