extends Node

func is_surface_too_steep(object : CharacterBody3D,  normal : Vector3) -> bool:
	return normal.angle_to(Vector3.UP) > object.floor_max_angle;

func _run_body_test_motion(object : CharacterBody3D, from : Transform3D, motion : Vector3, result = null) -> bool:
	
	if not result: PhysicsTestMotionParameters3D.new();
	var params = PhysicsTestMotionParameters3D.new();
	
	params.from = from;
	params.motion = motion;
	return PhysicsServer3D.body_test_motion(object.get_rid(), params, result);


#region stairs code
func _snap_down_to_stairs_check(object: CharacterBody3D, stairsBelow : RayCast3D, cameraComponent = null) -> void:
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
	if not object.is_on_floor() and not object._snapped_to_stairs_last_frame: return false
	# Don't snap stairs if trying to jump, also no need to check for stairs ahead if not moving
	if object.velocity.y > 0 or (object.velocity * Vector3(1,0,1)).length() == 0: return false
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

func clip_velocity(object : CollisionObject3D, normal: Vector3, overbounce : float, delta : float) -> void:
	
	var backoff = object.velocity.dot(normal) * overbounce
	
	if backoff >= 0: return
	
	var change = normal * backoff
	object.velocity -= change
	
	var adjust = object.velocity.dot(normal)
	if adjust < 0.0:
		object.velocity -= normal * adjust
