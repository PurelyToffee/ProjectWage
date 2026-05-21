class_name PlayerGrenade extends ProjectileParent

@export var explosion_scene: PackedScene

var max_bounces              : int   = 5
var damage_multiplier_per_bounce : float = 2.0
var base_damage              : float = 50.0
var fuse_seconds             : float = 3.0
var bounce_count             : int   = 0
var current_damage           : float = base_damage
var exploded                 : bool  = false

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
	return false


func launch(direction: Vector3, launch_speed: float = 0.0) -> void:
	var dir := direction.normalized()
	if dir.cross(Vector3.UP).length() > 0.001:
		look_at(global_position + dir, Vector3.UP)

	_velocity        = dir * launch_speed
	linear_velocity  = _velocity
	angular_velocity = dir.cross(Vector3.UP).normalized() * randf_range(10.0, 20.0)


func explode() -> void:
	if exploded:
		return
	exploded = true
	var explosion = LevelController.create_scene(explosion_scene)
	explosion.global_position = global_position
	explosion.damage           = current_damage
	queue_free()
