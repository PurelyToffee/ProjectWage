class_name PlayerGrenade extends ProjectileParent

@export var explosion_scene: PackedScene

var max_bounces              : int   = 5
var damage_multiplier_per_bounce : float = 2.0
var base_damage              : float = 125.0
var fuse_seconds             : float = 3.0
var bounce_count             : int   = 0
var current_damage           : float = base_damage
var exploded                 : bool  = false

#region pistol splinter
const SPLINTER_TRACER_SCENE := preload("uid://b0o05n4mcvp16")
const SPLINTER_DAMAGE_NUMBER := preload("uid://bb7dhymeeqtxl")

## Radius (m) the splinter searches for enemies when the grenade is shot.
@export var splinter_radius : float = 25.0
## Enemies splintered to = base + per_bounce * bounce_count (rounded up).
@export var splinter_enemies_base : float = 1.0
@export var splinter_enemies_per_bounce : float = 1.0
## Damage of each splintered shot = base + per_bounce * bounce_count.
@export var splinter_damage_base : float = 50.0
@export var splinter_damage_per_bounce : float = 50.0
#endregion

# Our own velocity — Godot's RigidBody velocity is only used to move the body,
# we overwrite it every frame from this.
var _velocity     : Vector3 = Vector3.ZERO
var _gravity      : float   = 9.8   # tweak to taste
var _bounciness   : float   = 0.8  # speed retained after each bounce
var _friction     : float   = 1.  # horizontal damping on ground contact


func _ready() -> void:
	current_damage = base_damage
	# Disable all of Godot's built-in bounce / damping so we have full control.
	physics_material_override       = PhysicsMaterial.new()
	physics_material_override.bounce    = 0.0
	physics_material_override.friction  = 0.0
	linear_damp  = 0.0
	angular_damp = 0.05
	_start_fuse()


func _start_fuse() -> void:
	await get_tree().create_timer(fuse_seconds).timeout
	if not exploded and is_inside_tree():
		explode()


# ProjectileParent calls this each frame — we handle gravity ourselves.
func _drive_motion(_delta: float) -> void:
	pass


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if exploded:
		return

	var dt := state.step

	# Apply gravity manually.
	_velocity.y -= _gravity * dt

	# Handle contacts.
	for i in state.get_contact_count():
		var normal := state.get_contact_local_normal(i)

		# Only reflect if we're moving into the surface.
		if _velocity.dot(normal) >= 0.0:
			continue

		# Reflect and scale down by bounciness.
		_velocity = _velocity.bounce(normal) * _bounciness

		# Bleed a little horizontal speed to simulate friction.
		var horizontal := _velocity * Vector3(1, 0, 1)
		_velocity     -= horizontal * (1.0 - _friction)

		_handle_body_contact(state.get_contact_collider_object(i))
		break   # one reflection per frame is enough

	# Hand our velocity back to the physics engine.
	state.linear_velocity = _velocity


func _on_area_3d_body_entered(_body: Node3D) -> void:
	pass


var _last_bounce_frame : int = -1

func _handle_body_contact(body: Object) -> bool:
	if exploded or body == null:
		return false
	
	var frame := Engine.get_physics_frames()
	if frame == _last_bounce_frame:
		return false
		
	_last_bounce_frame = frame

	if body.is_in_group("enemy"):
		explode()
		return true
		
	bounce_count += 1
	current_damage *= damage_multiplier_per_bounce
	if bounce_count >= max_bounces:
		explode()
		return true
	play_bounce()
	return false


func launch(direction: Vector3, launch_speed: float = 0.0) -> void:
	var dir := direction.normalized()
	if dir.cross(Vector3.UP).length() > 0.001:
		look_at(global_position + dir, Vector3.UP)

	_velocity        = dir * launch_speed
	linear_velocity  = _velocity
	angular_velocity = dir.cross(Vector3.UP).normalized() * randf_range(10.0, 20.0)


func explode() -> void:
	var explode_event = FmodServer.create_event_instance_with_guid("{4000df03-b12c-4692-8f70-b04a67daaea8}")
	explode_event.set_3d_attributes(global_transform)
	explode_event.start()
	explode_event.release()
	if exploded:
		return
	exploded = true
	var explosion = LevelController.create_scene(explosion_scene)
	explosion.player_damage = 20;
	explosion.global_position = global_position
	explosion.damage           = current_damage
	queue_free()

func play_bounce():
	var bounce_event = FmodServer.create_event_instance_with_guid("{a8e88cdf-613d-4217-8a1c-bb864387f1ea}")
	bounce_event.set_3d_attributes(global_transform)
	bounce_event.start()
	bounce_event.release()

#region pistol splinter

# Called by the pistol when its hitscan hits this grenade. Splinters the shot to
# nearby enemies, scaling both the number of targets and the damage with how many
# times the grenade has bounced, then detonates.
func splinter() -> void:
	if exploded:
		return

	var target_count := int(ceil(splinter_enemies_base + splinter_enemies_per_bounce * bounce_count))
	var shot_damage := splinter_damage_base + splinter_damage_per_bounce * bounce_count

	for enemy in _nearest_enemies(target_count):
		_splinter_hit(enemy, shot_damage)

	explode()


# Closest valid (alive, active) enemies within splinter_radius, up to count.
func _nearest_enemies(count : int) -> Array:
	var candidates := []
	for enemy in get_tree().get_nodes_in_group("enemy"):
		# The "enemy" group also contains child detection shapes — only target bodies.
		if not (enemy is ParentEnemy):
			continue
		if enemy.disabled or enemy.is_dead() or enemy.get_health() <= 0:
			continue
		var dist := global_position.distance_to(enemy.global_position)
		if dist > splinter_radius:
			continue
		candidates.append({ "enemy": enemy, "dist": dist })

	candidates.sort_custom(func(a, b): return a.dist < b.dist)

	var result := []
	for i in mini(count, candidates.size()):
		result.append(candidates[i].enemy)
	return result


func _splinter_hit(enemy : ParentEnemy, shot_damage : float) -> void:
	var center := enemy.get_center_point()
	var target_pos : Vector3 = center.global_position if center else enemy.global_position

	# Visual splinter beam from the grenade to the enemy.
	var tracer = SPLINTER_TRACER_SCENE.instantiate()
	get_tree().current_scene.add_child(tracer)
	tracer.fire(global_position, target_pos)

	if enemy.is_immortal():
		return

	var died : bool = enemy.take_damage(shot_damage)

	var damage_number = LevelController.create_scene(SPLINTER_DAMAGE_NUMBER)
	damage_number.global_position = target_pos
	damage_number.init(shot_damage, false)

	LevelController.add_score(
		LevelController.HIT_BY_PLAYER,
		enemy.score_award,
		LevelController.get_hit_score_arguments(died, LevelController.player.velocity.length(), !MovementUtils.really_on_floor(enemy))
	)

#endregion
