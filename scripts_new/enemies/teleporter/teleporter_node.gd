class_name TeleporterNode extends Node3D

var occupied := false;


func teleport_to(object : CharacterBody3D) -> TeleporterNode:
	
	object.global_position = global_position;
	occupy();
	
	return self;
	
func is_occupied() -> bool:
	return occupied;
	
func occupy() -> void:
	occupied = true;
	
func leave() -> void:
	occupied = false;
