extends Area3D


var min_kick_strength := 12;
var height_bonus := 20;
var kick_height := 3;

var parry_hold := 0.2; #Add a bit of leeway for a parry.

func _ready() -> void:
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	var found_body := false;
	var power_kickable_bodies = [];
	var killed := false;
	
	parry_check();
	
	for body in self.get_overlapping_bodies():
		
		print(body)
		if body.is_in_group("projectile") :
			
			if body.is_parryable():
				body.parry(MovementUtils.get_look_direction_vector(LevelController.player_camera));
			
		
		if !body.is_in_group("enemy") : continue;
		
		found_body = true;
		if body.is_power_kickable() :
			
			#If it's the first object the kick is meeting, do a power kick
			if power_kickable_bodies.size() == 0:
				LevelController.power_kick(height_bonus, 12);
			
			body.power_kick();
			power_kickable_bodies.append(body);
		
		var body_pos = body.global_position
		var kick_dir = MovementUtils.get_look_direction_vector(LevelController.player_camera);
		
		var flat_player_spd = MovementUtils.get_horizontal_vector(LevelController.player.velocity);
		var kick_force = max(abs(flat_player_spd.length() * 1.5), min_kick_strength);
	
		var damage = 50 * (1 + LevelController.player.velocity.length()/8);
		
		if body.is_in_group("dynamic"):
			body.velocity = Vector3.ZERO;
			MovementUtils.apply_knockback(body, kick_dir, kick_force * body.knockback_multiplier, kick_height if kick_dir.y < 0.5 else 0.)
		
		if !body.has_been_parryed:
			
			if body.is_parryable():
				body.parry();
			else:
				
				killed = body.take_damage(damage);
				LevelController.add_score(
					LevelController.HIT_BY_PLAYER, 
					50, 
					LevelController.get_hit_score_arguments(true, LevelController.player.velocity.length(), body.blown_away)
				)
		else:
			killed = body.take_damage(damage);
			
		body.blow_away();
	
	#Give the score for each object that was power kicked.
	if !MovementUtils.really_on_floor(LevelController.player):
		
		for body in power_kickable_bodies:
			
			LevelController.power_kick_score(body.is_dead(), !MovementUtils.really_on_floor(body))
		
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
	
