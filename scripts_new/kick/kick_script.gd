extends Area3D


var min_kick_strength := 12;
var height_bonus := 16;
var kick_height := 12;

var parry_hold := 0.2; #Add a bit of leeway for a parry.

func _ready() -> void:
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	var found_body := false;
	var blown_body = null;
	
	parry_check();
	
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

		var strength = Vector3(kick_dir.x * kick_force, (max(kick_dir.y, 0.4) if body.is_on_floor() else kick_dir.y) * kick_height, kick_dir.z * kick_force)
		if body is RigidBody3D:
			body.apply_impulse(strength)
		elif body is CharacterBody3D:
			body.velocity = strength;
		
		if body.is_parryable():
			body.parry();
		
		body.blow_away();
	
	if found_body and !LevelController.player.is_on_floor() and blown_body != null:
		LevelController.power_kick(height_bonus)
		#LevelController.player.force_uncrouch();
	

func parry_check() -> bool:
	
	var parried = false;
	for area in get_overlapping_areas():
		if area.is_in_group("parryable"):
			area.parry();
			parried = true;
			continue;
			
	return parried;
	

func _physics_process(delta: float) -> void:
	
	parry_hold = maxf(parry_hold - delta, 0.);
	if parry_check() or parry_hold == 0: queue_free()
	
