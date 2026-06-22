extends Area3D

const DAMAGE_NUMBER = preload("uid://bb7dhymeeqtxl")

var min_kick_strength := 12;
var height_bonus := 20;
var kick_height := 3;

var parry_hold := 0.2; #Add a bit of leeway for a parry.

var power_kickable_bodies := [];

func _ready() -> void:

	await get_tree().physics_frame
	await get_tree().physics_frame
	var whiffed = true
	var true_parry = false
	var found_body := false;
	power_kickable_bodies = [];
	var killed := false;

	parry_check();

	#Projectiles have an area3D bigger than the body so they can find the player before colliding with the environment.
	#As such, we need to check for the area.
	for area in self.get_overlapping_areas():
		var body = area.get_parent()

		if body.is_in_group("projectile") :

			if body.is_parryable():
				whiffed = false
				true_parry = true
				#If it's the first object the kick is meeting, do a power kick
				power_kick(body)
				body.parry(MovementUtils.get_look_direction_vector(LevelController.player_camera));

	for body in self.get_overlapping_bodies():

		if body.is_in_group("projectile") :

			if body.is_parryable():
				whiffed = false
				true_parry = true
				#If it's the first object the kick is meeting, do a power kick
				power_kick(body)
				body.parry(MovementUtils.get_look_direction_vector(LevelController.player_camera));

		if !body.is_in_group("enemy") : continue;
		whiffed = false
		found_body = true;
		if body.is_power_kickable() :

			#If it's the first object the kick is meeting, do a power kick
			power_kick(body)
			body.power_kick();

		var body_pos = body.global_position
		var kick_dir = MovementUtils.get_look_direction_vector(LevelController.player_camera);

		var flat_player_spd = MovementUtils.get_horizontal_vector(LevelController.player.velocity);
		var kick_force = max(abs(flat_player_spd.length() * 1.5), min_kick_strength);

		var damage = 50 * (1 + LevelController.player.velocity.length()/8);

		if body.is_in_group("dynamic"):
			body.velocity = Vector3.ZERO;
			MovementUtils.apply_knockback(body, kick_dir, kick_force * body.knockback_multiplier, kick_height if kick_dir.y < 0.5 else 0.)

		var did_damage := false;
		if !body.has_been_parryed:

			if body.is_parryable():
				true_parry = true
				body.parry();
			else:

				killed = body.take_damage(damage);
				did_damage = true;
				LevelController.add_score(
					LevelController.HIT_BY_PLAYER,
					50,
					LevelController.get_hit_score_arguments(true, LevelController.player.velocity.length(), body.blown_away)
				)
		else:
			killed = body.take_damage(damage);
			did_damage = true;

		#Show a big "kick" flavour text where the enemy was struck.
		if did_damage:
			spawn_kick_number(body)

		body.blow_away();

	#Give the score for each object that was power kicked.
	if !MovementUtils.really_on_floor(LevelController.player):
		for body in power_kickable_bodies:

			if body.is_in_group("projectile"):
				LevelController.power_kick_score()
			else:
				LevelController.power_kick_score(body.is_dead(), !MovementUtils.really_on_floor(body))

		#LevelController.player.force_uncrouch();
	if whiffed:
		play_whiff()
	else:
		if true_parry:
			play_parry()
		else:
			play_normal()


func spawn_kick_number(body) -> void:
	var dmg_number = LevelController.create_scene(DAMAGE_NUMBER)
	var center = body.get_center_point()
	dmg_number.global_position = center.global_position if center else body.global_position
	dmg_number.init(0, false, true)


func power_kick(body) -> void:
	if power_kickable_bodies.size() == 0:
		LevelController.power_kick(height_bonus, 12);

	power_kickable_bodies.append(body);

# despite the name, this is not just a check and applies parry to objects
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

func play_whiff():
	var kick_event = FmodServer.create_event_instance_with_guid("{d3db67d8-be01-421d-8ca5-71eee10593d9}")
	kick_event.set_3d_attributes(global_transform)
	kick_event.start()
	kick_event.release()

func play_normal():
	var kick_event = FmodServer.create_event_instance_with_guid("{61bddfdd-20d5-4992-9880-02a9e8933112}")
	kick_event.set_3d_attributes(global_transform)
	kick_event.start()
	kick_event.release()

func play_parry():
	var kick_event = FmodServer.create_event_instance_with_guid("{f1b3b26a-be51-462a-860d-6cd98eb858a9}")
	kick_event.set_3d_attributes(global_transform)
	kick_event.start()
	kick_event.release()
