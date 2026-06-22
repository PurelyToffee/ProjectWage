class_name ArenaWall extends StaticBody3D
@onready var wall_coll: CollisionShape3D = %WallColl


var enabled := true;

## If true, the wall is up (blocking) when the level spawns.
## If false, it starts disabled and only raises when the arena is triggered —
## use this for entrance walls that should lock the player in on entry.
@export var start_active : bool = true;


func _ready() -> void:
	if !start_active:
		deactivate();


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
