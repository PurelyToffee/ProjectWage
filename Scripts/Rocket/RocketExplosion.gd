extends Area3D

@export var explosion_force := 60

func _ready() -> void:
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	for body in self.get_overlapping_bodies():
		var body_pos = body.global_position

		print(body)

		var force_dir := self.global_position.direction_to(body_pos)
		var body_dist = (body_pos - self.global_position).length()
		

		var falloff := 1.0 - clampf(body_dist / 3.5, 0.0, 1.0)
		var base_force := explosion_force * falloff

		if body is RigidBody3D:
			var impulse = force_dir * base_force / max(0.01, body.mass)
			body.apply_impulse(impulse)
			
		elif body is CharacterBody3D:
			
			print("%s %s" % [body, base_force])
			
			var adjusted_dir := Vector3(force_dir.x, abs(force_dir.y) + 0.3, force_dir.z).normalized()
			body.velocity += adjusted_dir * (base_force / 4.0)

	queue_free()
