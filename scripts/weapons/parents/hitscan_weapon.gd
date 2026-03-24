class_name HitscanWeapon extends BaseWeapon

const BULLET_TRACER_SCENE = preload("uid://b0o05n4mcvp16")

var final_damage := damage

func intersect_hitscan() -> Dictionary:
	var camera = LevelController.player_camera
	if not camera or not LevelController.player_attack_origin or not LevelController.player:
		return {}

	var origin: Vector3 = LevelController.player_camera.global_position
	var aim_dir: Vector3 = -camera.global_basis.z
	aim_dir.x += randf_range(-spread, spread)
	aim_dir.y += randf_range(-spread, spread)
	aim_dir = aim_dir.normalized()

	var query := PhysicsRayQueryParameters3D.create(origin, origin + aim_dir * fire_range)
	query.collision_mask = 5  # layer 1-3 = level and enemy layer (respectively)



	return camera.get_world_3d().direct_space_state.intersect_ray(query)

func spawn_tracer(start: Vector3, end: Vector3, offset: Vector2):

	var cam = LevelController.player_camera

	# convert screen offset → world offset
	var right = cam.global_basis.x
	var up = cam.global_basis.y

	var offset_start = start + right * offset.x + up * offset.y

	var tracer = BULLET_TRACER_SCENE.instantiate()
	get_tree().current_scene.add_child(tracer)
	tracer.fire(offset_start, end)

func fire() -> void:
	
	set_fire_cooldown(fire_rate)
	reduce_ammo(ammo_per_shot)
	var result := intersect_hitscan()
	
	var origin = LevelController.player_attack_origin.global_position;
	var hit_pos: Vector3
	if result.is_empty():
		hit_pos = origin + (-LevelController.player_camera.global_basis.z) * 50.;
	else:
		hit_pos = result.position

	spawn_tracer(origin, hit_pos, Vector2(0.3, 0))
	
	if result.is_empty():
		#print("[", weapon_name, "] ray miss")
		return
	#print("[", weapon_name, "] ray hit: ", result.collider.name, " at ", result.position)
	
	var node = result.collider
	if !node.is_in_group("damageable"):
		return

	# find which collision shape was hit
	var shape_index = result.shape
	var owner_id = node.shape_find_owner(shape_index)
	var hitbox = node.shape_owner_get_owner(owner_id)

	# detect headshot
	var is_headshot = hitbox.is_in_group("head")
	var health = node.health_component
	
	if health.get_hp() <= 0 : return;
	

	if health:
		if can_headshot:
			final_damage = resolve_damage(damage, is_headshot)
		else:
			final_damage = damage
		#print("[", weapon_name, "] dealing ", final_damage, " dmg -> hp now: ", health.hp - final_damage)
		var died = health.take_damage(final_damage)
		LevelController.add_score(
			LevelController.HIT_BY_PLAYER, 
			node.score_award, 
			LevelController.get_hit_score_arguments(is_headshot, died, false, false, LevelController.player.velocity.length(), MovementUtils.really_on_floor(node))
			)
		
	#else:
		#print("[", weapon_name, "] no HealthComponent found on: ", result.collider.name)

	
func resolve_damage(base: float, is_headshot: bool) -> float:
	return base * headshot_multiplier if is_headshot else base
