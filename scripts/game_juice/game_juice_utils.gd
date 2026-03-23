extends Node

var camera_shake_duration : float = 0.;
var camera_shake_max_duration : float = 0.;
var camera_shake_strength : float = 0.;
var camera_original_position : Vector3 = Vector3.ZERO;

var hit_stop_active : bool = false;


func _process(delta : float) -> void:
	
	#region Shake Camera
	if !hit_stop_active and camera_shake_duration > 0.:
		
		var strength = camera_shake_strength * (camera_shake_duration/camera_shake_max_duration)
		print("strength %s %s %s" % [delta, camera_shake_duration, strength])
		
		LevelController.player_camera.position  = camera_original_position + Vector3(
			randf_range(-strength, strength),
			randf_range(-strength, strength),
			0.0
		)
		
		camera_shake_duration = max(camera_shake_duration - delta, 0)
		
		if camera_shake_duration == 0.:
			LevelController.player_camera.position  = camera_original_position
			camera_original_position = Vector3.ZERO;

	#endregion

func hit_stop(timeScale : float = 0.1, duration : float = 0.3) -> void:
	Engine.time_scale = timeScale;
	hit_stop_active = true;
	
	await get_tree().create_timer(duration, true, false, true).timeout
	
	Engine.time_scale = 1.;
	hit_stop_active = false;


func hit_flash(duration : float = 0.1) -> void:
	
	var subViewPort = LevelController.gameplay_viewport_container;
	
	subViewPort.material.set_shader_parameter("active", true)
	await get_tree().create_timer(duration).timeout
	subViewPort.material.set_shader_parameter("active", false)
	

func shake_camera(duration: float = 1.5, intensity: float = 1.) -> void:
	if camera_original_position == Vector3.ZERO: camera_original_position = LevelController.player_camera.position
	camera_shake_duration = duration
	camera_shake_max_duration = duration
	camera_shake_strength = intensity
