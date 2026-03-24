class_name ExplosionParent extends Area3D

@export var explosion_force := 15;
@export var damage := 0;

func _ready() -> void:
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	for body in self.get_overlapping_bodies():
		
		if !body.is_in_group("dynamic"): continue;
		
		var body_pos = body.global_position
		var force_dir := self.global_position.direction_to(body_pos)
		var body_dist := (body_pos - self.global_position).length()
		var falloff := 1.0 - clampf(body_dist / 3.5, 0.0, 1.0)
		
		var adjusted_dir : Vector3 = Vector3(force_dir.x, abs(force_dir.y) + 0.3, force_dir.z).normalized();
		
		var force := explosion_force * falloff
		if !body.is_in_group("player") : force *= 1.2;
		
		MovementUtils.apply_knockback(body, adjusted_dir, force)
		
		if body.is_in_group("damageable"):
			body.health_component.take_damage(damage * falloff);
			
		if body.is_in_group("enemy"):
			body.blow_away();
		
		if body.is_in_group("player") and LevelController.player_is_crouched():
			body.change_crouch_dir(adjusted_dir)
			
	queue_free()
