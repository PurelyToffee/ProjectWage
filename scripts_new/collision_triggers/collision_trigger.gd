class_name CollisionTrigger extends Area3D

var active := true;


func _ready() -> void: 
	body_entered.connect(trigger)

func trigger(body) -> void:
	
	if !active : return;
	
	
func set_active(val : bool) -> void:
	active = val;
	
func get_active() -> bool:
	return active;
