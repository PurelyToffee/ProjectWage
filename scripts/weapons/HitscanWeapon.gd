class_name HitscanWeapon extends BaseWeapon

func _intersect_hitscan() -> Dictionary:
	var camera := Global.player_camera
	if not camera or not Global.player_attack_origin or not Global.player:
		return {}

	var origin: Vector3 = Global.player_attack_origin.global_position
	var aim_dir: Vector3 = -camera.global_basis.z
	aim_dir.x += randf_range(-spread, spread)
	aim_dir.y += randf_range(-spread, spread)
	aim_dir = aim_dir.normalized()

	var query := PhysicsRayQueryParameters3D.create(origin, origin + aim_dir * fire_range)
	query.exclude = [Global.player.get_rid()]

	return camera.get_world_3d().direct_space_state.intersect_ray(query)

func _shoot_ray() -> void:
	var result := _intersect_hitscan()
	if result.is_empty():
		print("[", weapon_name, "] ray miss")
		return

	print("[", weapon_name, "] ray hit: ", result.collider.name, " at ", result.position)
	var health := _find_health(result.collider)
	var is_headshot := false
	# TODO: determine is_headshot from hitbox metadata or groups.

	if health:
		var final_damage := _resolve_damage(damage, is_headshot)
		print("[", weapon_name, "] dealing ", final_damage, " dmg -> hp now: ", health.hp - final_damage)
		health.take_damage(final_damage)
	else:
		print("[", weapon_name, "] no HealthComponent found on: ", result.collider.name)

func _find_health(node: Node) -> HealthComponent:
	var current := node
	for _i in 3:
		if current.has_node("HealthComponent"):
			return current.get_node("HealthComponent")
		if current.get_parent() != null:
			current = current.get_parent()
		else:
			break
	return null
