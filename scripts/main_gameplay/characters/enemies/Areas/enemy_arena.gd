class_name EnemyArena extends CollisionTrigger
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D

var enemies := []


func trigger(body) -> void:

	if !active : return;
	if !body.is_in_group("player") : return;
	
	
	for enemy : ParentEnemy in enemies:
		enemy.activate()
	
	active = false;
	
	pass;

func set_dead(object):
	pass;

# Called when the node enters the scene tree for the first time.
func _ready():
	
	super._ready()
	
	await get_tree().physics_frame
	await get_tree().physics_frame

	var bodies = get_overlapping_bodies()

	for enemy in bodies:
		if !enemy.is_in_group("enemy"): continue;
		enemy.set_arena(self)
		enemy.deactivate()
		enemies.append(enemy)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
