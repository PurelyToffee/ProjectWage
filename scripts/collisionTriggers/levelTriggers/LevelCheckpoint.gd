class_name LevelCheckpoint extends CollisionTrigger

@export var respawn_offset : Vector3 = Vector3.ZERO;


func trigger() -> void:
	
	super.trigger();
	
	LevelController.set_checkpoint(self);
	
	set_active(false);

func respawn_entity(ent : CharacterBody3D) -> void:
	
	ent.global_position = self.global_position + respawn_offset;


func _on_body_entered(body: Node3D) -> void:
	
	if body.is_in_group("player"):
		trigger();
