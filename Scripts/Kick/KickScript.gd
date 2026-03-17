extends Area3D


var min_kick_strength := 12;
var height_bonus := 16;
var kick_height := 12;

func _ready() -> void:
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	var found_body := false;
	var blown_body = null;
	
	for body in self.get_overlapping_bodies():
		if !body.is_in_group("enemy") : continue;
		
		found_body = true;
		if body.is_blown_away() :
			blown_body = body;
		
		var body_pos = body.global_position
		var kick_dir = -LevelController.player_camera.global_transform.basis.z
		
		
		var flat_player_spd = MovementUtils.get_horizontal_vector(LevelController.player.velocity);
		var kick_force = max(abs(flat_player_spd.length() * 1.5), min_kick_strength);
		
		
		var damage = 25 * (1 + LevelController.player.velocity.length()/8);
		body.health_component.take_damage(damage);

		print(kick_dir.y)
		var strength = Vector3(kick_dir.x * kick_force, (max(kick_dir.y, 0.4) if body.is_on_floor() else kick_dir.y) * kick_height, kick_dir.z * kick_force)
		if body is RigidBody3D:
			body.apply_impulse(strength)
		elif body is CharacterBody3D:
			body.velocity = strength;
		
		body.blow_away();
		
	if found_body and !LevelController.player.is_on_floor() and blown_body != null:
		LevelController.player.velocity.y = abs(LevelController.player.velocity.y) + height_bonus;
		GameJuice.hit_stop()
		#LevelController.player.force_uncrouch();
	
	queue_free()
