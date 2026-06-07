class_name ProjectileWeapon extends BaseWeapon

var projectile_scene : PackedScene
var launch_speed := 30.0

func fire() -> void:
	if projectile_scene == null:
		return

	set_fire_cooldown(fire_rate)
	reduce_ammo(ammo_per_shot)

	var camera : Camera3D = LevelController.player_camera
	var origin : Vector3 = LevelController.player_attack_origin.global_position
	var aim_dir : Vector3 = -camera.global_basis.z

	var projectile = projectile_scene.instantiate()
	_configure_projectile(projectile)

	get_tree().current_scene.add_child(projectile)
	projectile.global_position = origin
	if LevelController.player and projectile is PhysicsBody3D:
		projectile.add_collision_exception_with(LevelController.player)

	projectile.launch(aim_dir, launch_speed)

func _configure_projectile(_projectile) -> void:
	pass
