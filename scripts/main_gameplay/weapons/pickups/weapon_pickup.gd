class_name WeaponPickup extends CollisionTrigger

@export var weapon_id : String = "";

func trigger(body) -> void:

	if !active : return;
	if !body.is_in_group("player") : return;

	var added : bool = body.weapon_manager.add_weapon_by_id(weapon_id)
	if !added : return;

	set_active(false);
	queue_free();
