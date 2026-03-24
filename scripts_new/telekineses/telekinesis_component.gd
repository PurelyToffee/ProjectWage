class_name TekelinesisComponent extends Node

var previous_target : CharacterBody3D;
var target_enemy : CharacterBody3D;

var max_cooldown : float = 5;
var cooldown : float = 0;

var shape_radius := 8.0;
var shape_distance := 32.0;


var enabled = true;

func find_target() -> Node3D:
	var cam = LevelController.player_camera
	var origin = cam.global_transform.origin
	var forward = -cam.global_transform.basis.z

	var cylinder = CylinderShape3D.new()
	cylinder.radius = shape_radius
	cylinder.height = shape_distance

	var transform = Transform3D()
	transform.origin = cam.global_transform.origin + forward * cylinder.height / 2
	transform.basis = cam.global_transform.basis * Basis(Vector3.RIGHT, PI / 2)

	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = cylinder
	query.transform = transform
	query.collide_with_bodies = true
	query.exclude = [LevelController.player]
	query.collision_mask = 4

	var results = cam.get_world_3d().direct_space_state.intersect_shape(query, 32)

	if results.is_empty(): return null

	# Pick enemy closest to screen center
	var best_enemy = null
	var best_screen_dist = 1e10
	var screen_center = get_viewport().get_visible_rect().size / 2

	for hit in results:
		
		var enemy = hit.collider

		# Only consider enemies in the telekinesis_target group
		if not enemy.is_in_group("telekinesis_target"): continue;
		if enemy.get_center_point() == null : continue;

		var screen_pos = cam.unproject_position(enemy.global_position)
		var dist = screen_pos.distance_to(screen_center)
		if dist < best_screen_dist:
			best_screen_dist = dist
			best_enemy = enemy

	return best_enemy
	
func enable() -> void:
	enabled = true;
	
func disable() -> void:
	enabled = false;
	
func is_enabled() -> bool:
	return enabled;

func update(delta):

	cooldown = max(cooldown - delta, 0);

	if cooldown > 0 : 
		LevelController.gameplay_HUD.set_telekinesis_target(null)
		return;


	target_enemy = find_target()
	LevelController.gameplay_HUD.set_telekinesis_target(target_enemy)
	
	previous_target = target_enemy


func launch_enemy() -> void:
	
	if cooldown > 0 or LevelController.gameplay_HUD.get_telekinesis_target() == null : return;
	
	target_enemy.blow_away();
	target_enemy.velocity = Vector3.ZERO;
	target_enemy.velocity.y = 20;
	cooldown = max_cooldown;
