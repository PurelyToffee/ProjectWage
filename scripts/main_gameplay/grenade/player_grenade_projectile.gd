class_name PlayerGrenade extends ProjectileParent

@export var explosion_scene: PackedScene

var max_bounces : int = 5
var damage_multiplier_per_bounce : float = 2.0
var base_damage : float = 50.0
var fuse_seconds : float = 3.0

var bounce_count : int = 0
var current_damage : float = 0.0
var exploded : bool = false

func _ready() -> void:
	current_damage = base_damage
	_start_fuse()

func _start_fuse() -> void:
	await get_tree().create_timer(fuse_seconds).timeout
	if not exploded and is_inside_tree():
		explode()

# Override: let gravity + physics_material bouncing drive motion.
func _drive_motion(_delta: float) -> void:
	pass

# Override: only the RigidBody3D contact counts as a bounce; Area3D is wider
# than the body and would double-fire the hook.
func _on_area_3d_body_entered(_body: Node3D) -> void:
	pass

# Override: explode on enemy contact, bounce + scale damage otherwise.
func _handle_body_contact(body: Node) -> bool:
	if exploded:
		return false

	if body.is_in_group("enemy"):
		explode()
		return true

	bounce_count += 1
	current_damage *= damage_multiplier_per_bounce

	if bounce_count == max_bounces:
		explode()
		return true

	return false

func launch(direction: Vector3, launch_speed: float = 0.0) -> void:
	
	var dir := direction.normalized()
	if dir.cross(Vector3.UP).length() > 0.001:
		look_at(global_position + dir, Vector3.UP)
		
	linear_velocity = dir * launch_speed
	angular_velocity = dir.cross(Vector3.UP).normalized() * randf_range(10.0, 20.0)

func explode() -> void:
	if exploded:
		return
	exploded = true

	var explosion = LevelController.create_scene(explosion_scene)
	explosion.global_position = global_position
	explosion.damage = current_damage

	queue_free()
