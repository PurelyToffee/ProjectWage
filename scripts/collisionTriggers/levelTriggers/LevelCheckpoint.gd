class_name LevelCheckpoint extends CollisionTrigger

@export var respawn_offset : Vector3 = Vector3.ZERO;


func trigger(body) -> void:
	
	super.trigger(body);
	
	LevelController.set_checkpoint(self);
	
	set_active(false);

func respawn_entity(ent : CharacterBody3D) -> void:
	
	ent.global_position = self.global_position + respawn_offset;
