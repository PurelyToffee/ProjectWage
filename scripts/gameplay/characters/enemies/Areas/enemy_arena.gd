class_name EnemyArena extends CollisionTrigger
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D

var enemies := []

var arena_active := false;

@export var enemies_node : Node3D;
## Walls tied to this arena. Walls with start_active = false stay open until the
## arena is triggered, then raise to lock the player in (e.g. the entrance).
## All of them drop once the arena is cleared.
@export var arena_walls : Array[ArenaWall] = [];


func trigger(body) -> void:

	if !active : return;
	if !body.is_in_group("player") : return;


	for enemy : ParentEnemy in enemies:
		enemy.activate()

	#Raise every wall so any that started open (the entrance) lock behind the player.
	for wall : ArenaWall in arena_walls:
		if wall : wall.activate();

	active = false;
	arena_active = true;

	pass;

func set_dead(object):

	enemies.erase(object)

	if enemies.size() == 0:
		for wall : ArenaWall in arena_walls:
			if wall : wall.deactivate();

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
