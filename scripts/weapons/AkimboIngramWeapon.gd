class_name AkimboIngramWeapon extends BaseWeapon

const FIRE_RATE  := 0.07   # both guns fire together
const DAMAGE     := 8.0    # per bullet, 2 bullets per burst
# const MAX_AMMO   := 60     # 30 rounds per gun
const SPREAD     := 0.05   # radians of random spread
const RANGE      := 40.0   # meters :3

# var ammo := MAX_AMMO
var _fire_cooldown := 0.0

func _ready() -> void:
	weapon_name = "Akimbo Ingrams"

func update(delta: float) -> void:
	if _fire_cooldown > 0.0:
		_fire_cooldown -= delta

func can_fire() -> bool:
	return _fire_cooldown <= 0.0 # and ammo >= 2

func fire() -> void:
	_fire_cooldown = FIRE_RATE
	# ammo -= 2	print("[AkimboIngram] fired | ammo remaining: ", ammo)	_shoot_ray()
	_shoot_ray()

func _shoot_ray() -> void:
	var camera := Global.player_camera
	if not camera:
		return

	var origin: Vector3 = Global.player_attack_origin.global_position
	var aim_dir: Vector3 = -camera.global_basis.z
	aim_dir.x += randf_range(-SPREAD, SPREAD)
	aim_dir.y += randf_range(-SPREAD, SPREAD)
	aim_dir = aim_dir.normalized()

	var query := PhysicsRayQueryParameters3D.create(origin, origin + aim_dir * RANGE)
	query.exclude = [Global.player.get_rid()]

	var result := camera.get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		print("[AkimboIngram] ray miss")
		return

	print("[AkimboIngram] ray hit: ", result.collider.name, " at ", result.position)
	var health := _find_health(result.collider)
	if health:
		print("[AkimboIngram] dealing ", DAMAGE, " dmg -> hp now: ", health.hp - DAMAGE)
		health.take_damage(DAMAGE)
	else:
		print("[AkimboIngram] no HealthComponent found on: ", result.collider.name)

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

func get_ui_state() -> Dictionary:
	var state := super.get_ui_state()
	# state["ammo"] = ammo
	# state["max_ammo"] = MAX_AMMO
	return state
