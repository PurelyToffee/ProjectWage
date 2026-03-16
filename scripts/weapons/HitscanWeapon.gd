class_name HitscanWeapon extends BaseWeapon

@export var can_headshot := false

var final_damage := damage

func intersect_hitscan() -> Dictionary:
	var camera = Global.player_camera
	if not camera or not Global.player_attack_origin or not Global.player:
		return {}

	var origin: Vector3 = Global.player_attack_origin.global_position
	var aim_dir: Vector3 = -camera.global_basis.z
	aim_dir.x += randf_range(-spread, spread)
	aim_dir.y += randf_range(-spread, spread)
	aim_dir = aim_dir.normalized()

	var query := PhysicsRayQueryParameters3D.create(origin, origin + aim_dir * fire_range)
	query.collision_mask = 5  # layer 1-3 = level and enemy layer (respectively)

	return camera.get_world_3d().direct_space_state.intersect_ray(query)

func fire_shot() -> void:
	var result := intersect_hitscan()
	if result.is_empty():
		print("[", weapon_name, "] ray miss")
		return

	print("[", weapon_name, "] ray hit: ", result.collider.name, " at ", result.position)
	
	var node = result.collider;
	if !node.is_in_group("enemy") : return
	
	var health = node.health_component;
	var is_headshot := false

	if health:
		if can_headshot:
			final_damage = resolve_damage(damage, is_headshot)
		else:
			final_damage = damage
		print("[", weapon_name, "] dealing ", final_damage, " dmg -> hp now: ", health.hp - final_damage)
		health.take_damage(final_damage)
	else:
		print("[", weapon_name, "] no HealthComponent found on: ", result.collider.name)

	
func resolve_damage(base: float, is_headshot: bool) -> float:
	return base * headshot_multiplier if is_headshot else base
