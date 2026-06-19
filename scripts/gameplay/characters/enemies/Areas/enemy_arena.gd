class_name EnemyArena extends CollisionTrigger
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D

var enemies := []

var arena_active := false;

@export var enemies_node : Node3D;
@export var arena_wall : ArenaWall;


func trigger(body) -> void:

	if !active : return;
	if !body.is_in_group("player") : return;
	
	
	for enemy : ParentEnemy in enemies:
		enemy.activate()
	
	active = false;
	arena_active = true;
	
	pass;

func set_dead(object):
	
	enemies.erase(object)
	
	if enemies.size() == 0. and arena_wall:
		arena_wall.deactivate();
	
	pass;

# Called when the node enters the scene tree for the first time.
func _ready():
	
	super._ready()
	
	await get_tree().physics_frame
	await get_tree().physics_frame

	var bodies = get_overlapping_bodies()

	for enemy in bodies:
		if !enemy.is_in_group("enemy"): continue;
		add_enemy(enemy);
	
	if enemies_node:
		for enemy in enemies_node.get_children():
			if enemy is ParentEnemy:
				if !enemies.has(enemy):
					add_enemy(enemy);
	
	
func add_enemy(en : ParentEnemy) -> void:
	en.set_arena(self)
	en.deactivate()
	enemies.append(en)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
