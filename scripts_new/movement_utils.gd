extends Node

#region helpers


func distance_between_points(point_a : Vector3, point_b : Vector3):
	return point_a.distance_to(point_b);

func is_surface_too_steep(object : CharacterBody3D,  normal : Vector3) -> bool:
	return normal.angle_to(Vector3.UP) > object.floor_max_angle;


func get_look_direction_vector(object) -> Vector3:
	return -object.global_transform.basis.z

func get_horizontal_vector(vec : Vector3) -> Vector3:
	return Vector3(vec.x, 0, vec.z);

func really_on_floor(object: CollisionObject3D) -> bool:
	
	return object.is_on_floor() or object._snapped_to_stairs_last_frame;


func get_future_position(object: CharacterBody3D, time : float) -> Vector3:
	return object.get_center_point().global_position + object.velocity * maxf(time, 0.);

func redirect_velocity(speed : Vector3, normal : Vector3, margin : float = 0.5) -> Vector3:
	
	var projected = speed - normal * speed.dot(normal);
	
	if projected.length() > margin:
		projected = projected.normalized() * speed.length();
		speed.x = projected.x;
		speed.y = projected.y;
		speed.z = projected.z;
	
	return speed;

func sphere_redirect_velocity(velocity: Vector3, position: Vector3, sphere_center: Vector3, outward_bias_multiplier : float = 2.0) -> Vector3:
	var radial_normal = (position - sphere_center).normalized()
	
	# Remove radial component
	var tangent = velocity - radial_normal * velocity.dot(radial_normal)
	
	# Add slight outward push.
	# This is used in the chainer code to make sure the player is outside the radius on the next frame aswell, making it smoother.
	var outward_bias = radial_normal * outward_bias_multiplier;
	
	if tangent.length() > 0.001:
		return tangent.normalized() * velocity.length()
	
	return tangent

#endregion

func _run_body_test_motion(object : CharacterBody3D, from : Transform3D, motion : Vector3, result = null) -> bool:
	
	if not result: PhysicsTestMotionParameters3D.new();
	var params = PhysicsTestMotionParameters3D.new();
	
	params.from = from;
	params.motion = motion;
	return PhysicsServer3D.body_test_motion(object.get_rid(), params, result);

#region stairs code


func slope_speedup(object : CharacterBody3D) -> void:
	
	if object.is_on_floor():
		var floor_normal = object.get_floor_normal();
		var gravity_dir = Vector3.DOWN
		
		var downhill = gravity_dir - floor_normal * gravity_dir.dot(floor_normal)
		if downhill.length() > 0.001:
			downhill = downhill.normalized()
			object.velocity += downhill * ProjectSettings.get_setting("physics/3d/default_gravity") * object.get_physics_process_delta_time()

func _snap_down_to_stairs_check(object: CharacterBody3D, stairsBelow : RayCast3D, increaseSpeed : bool = false, cameraComponent = null) -> void:
	var did_snap := false
	# Modified slightly from tutorial. I don't notice any visual difference but I think this is correct.
	# Since it is called after move_and_slide, _last_frame_was_on_floor should still be current frame number.
	# After move_and_slide off top of stairs, on floor should then be false. Update raycast incase it's not already.
	stairsBelow.force_raycast_update()
	var floor_below : bool = stairsBelow.is_colliding() and not is_surface_too_steep(object, stairsBelow.get_collision_normal())
	var was_on_floor_last_frame = Engine.get_physics_frames() == object._last_frame_was_on_floor
	
	if not object.is_on_floor() and object.velocity.y <= 0 and (was_on_floor_last_frame or object._snapped_to_stairs_last_frame) and floor_below:
		var body_test_result = KinematicCollision3D.new()
		if object.test_move(object.global_transform, Vector3(0,-object.MAX_STEP_HEIGHT,0), body_test_result):
			if cameraComponent : cameraComponent._save_camera_pos_for_smoothing()
			var translate_y = body_test_result.get_travel().y
			object.position.y += translate_y
			object.apply_floor_snap()
			did_snap = true
			
	object._snapped_to_stairs_last_frame = did_snap


func _snap_up_stairs_check(object: CharacterBody3D, stairsAhead : RayCast3D, delta : float, cameraComponent = null) -> bool:

	if !really_on_floor(object): return false
	# Don't snap stairs if trying to jump, also no need to check for stairs ahead if not moving
	if object.velocity.y > 0 or (object.velocity * Vector3(1,0,1)).length() == 0: 
		return false
	var expected_move_motion = object.velocity * Vector3(1,0,1) * delta
	var step_pos_with_clearance = object.global_transform.translated(expected_move_motion + Vector3(0, object.MAX_STEP_HEIGHT * 2, 0))
	# Run a body_test_motion slightly above the pos we expect to move to, towards the floor.
	#  We give some clearance above to ensure there's ample room for the player.
	#  If it hits a step <= MAX_STEP_HEIGHT, we can teleport the player on top of the step
	#  along with their intended motion forward.
	var down_check_result = KinematicCollision3D.new()
	if (object.test_move(step_pos_with_clearance, Vector3(0,-object.MAX_STEP_HEIGHT*2,0), down_check_result)
	and (down_check_result.get_collider().is_class("StaticBody3D") or down_check_result.get_collider().is_class("CSGShape3D"))):
		var step_height = ((step_pos_with_clearance.origin + down_check_result.get_travel()) - object.global_position).y
		# Note I put the step_height <= 0.01 in just because I noticed it prevented some physics glitchiness
		# 0.02 was found with trial and error. Too much and sometimes get stuck on a stair. Too little and can jitter if running into a ceiling.
		# The normal character controller (both jolt & default) seems to be able to handled steps up of 0.1 anyway
		if step_height > object.MAX_STEP_HEIGHT or step_height <= 0.01 or (down_check_result.get_position() - object.global_position).y > object.MAX_STEP_HEIGHT: return false
		stairsAhead.global_position = down_check_result.get_position() + Vector3(0,object.MAX_STEP_HEIGHT,0) + expected_move_motion.normalized() * 0.1
		stairsAhead.force_raycast_update()
		if stairsAhead.is_colliding() and not is_surface_too_steep(object, stairsAhead.get_collision_normal()):
			if cameraComponent : cameraComponent._save_camera_pos_for_smoothing()
			object.global_position = step_pos_with_clearance.origin + down_check_result.get_travel()
			object.apply_floor_snap()
			object._snapped_to_stairs_last_frame = true
			return true
	return false
#endregion 

func apply_ground_friction(object : CollisionObject3D, delta) -> void:
	
	if object.ground_deccel == null: return;
	
	var control = max(object.velocity.length(), object.ground_deccel)
	var drop = control * object.ground_friction * delta
	var new_speed = max(object.velocity.length() - drop, 0.0)
	
	if object.velocity.length() > 0:
		new_speed /= object.velocity.length()
	object.velocity *= new_speed

func clip_velocity(object : CollisionObject3D, normal: Vector3, overbounce : float, delta : float) -> void:
	
	var backoff = object.velocity.dot(normal) * overbounce
	
	if backoff >= 0: return
	
	var change = normal * backoff
	object.velocity -= change
	
	var adjust = object.velocity.dot(normal)
	if adjust < 0.0:
		object.velocity -= normal * adjust


func apply_knockback(body: Node3D, direction: Vector3, force: float, vertical_bonus: float = 0.0, set_y_floor: bool = false, explosion : bool = false) -> void:
	
	if body == null:
		return

	if direction == Vector3.ZERO:
		return

	direction = direction.normalized()
	var impulse = direction * force
	impulse.y += vertical_bonus
	

	impulse.x *= body.knockback_multiplier if !explosion else body.explosion_knockback_multiplier;
	impulse.z *= body.knockback_multiplier if !explosion else body.explosion_knockback_multiplier;
	impulse.y *= body.vertical_knockback_multiplier if !explosion else body.explosion_vertical_knockback_multiplier;
	
	body.velocity += impulse;
	if set_y_floor:
		body.velocity.y = max(body.velocity.y, vertical_bonus)


var push_radius = 4.0
func soft_collide(object : CharacterBody3D, push_area : Area3D, delta : float, push_force : int = 50, ignore_groups = []) -> void:
	
	for body in push_area.get_overlapping_bodies():
		
		if body == self:
			continue;
			
		if !body.is_in_group("dynamic"):
			continue;
		
		var ignore = false;
		for g in ignore_groups:
			if body.is_in_group(g):
				ignore = true;
				break;
				
		if ignore : 
			continue;

		var dir = object.global_transform.origin - body.global_transform.origin;
		var dist = dir.length()

		if dist == 0 or dist > push_radius:
			continue;

		var push_dir = dir.normalized()
		var strength = (push_radius - dist) / push_radius
		var res = push_dir * strength * push_force;
		
		object.velocity += push_dir * strength * push_force * delta
