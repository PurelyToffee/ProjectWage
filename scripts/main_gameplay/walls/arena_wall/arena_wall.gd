class_name ArenaWall extends StaticBody3D
@onready var wall_coll: CollisionShape3D = %WallColl


var enabled := true;


func deactivate():
	
	enabled = false;
	visible = false
	set_process(false)
	set_physics_process(false)
	wall_coll.disabled = true;

# Enable enemy
func activate():
	
	enabled = true
	visible = true
	set_process(true)
	set_physics_process(true)

	call_deferred("enable_collisions")

func enable_collisions():
	wall_coll.disabled = false
