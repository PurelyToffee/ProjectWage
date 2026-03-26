extends Node

var camera_shake_duration : float = 0.;
var camera_shake_max_duration : float = 0.;
var camera_shake_strength : float = 0.;
var camera_original_position : Vector3 = Vector3.ZERO;

var hit_stop_active : bool = false;
var time_scale : float = 1.0;

func _process(delta : float) -> void:
	
	#region Shake Camera
	if !hit_stop_active and camera_shake_duration > 0.:
		
		var strength = camera_shake_strength * (camera_shake_duration/camera_shake_max_duration)
		
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

func get_time_scale() -> float:
	return time_scale;

func hit_stop(timeScale : float = 0.01, duration : float = 0.3) -> void:
	Engine.time_scale = timeScale;
	hit_stop_active = true;
	time_scale = timeScale;
	
	await get_tree().create_timer(duration, true, false, true).timeout
	
	Engine.time_scale = 1.;
	hit_stop_active = false;
	time_scale = 1.;


func hit_flash(duration : float = 0.1) -> void:
	
	var subViewPort = LevelController.gameplay_viewport_container;
	
	subViewPort.material.set_shader_parameter("active", true)
	await get_tree().create_timer(duration).timeout
	subViewPort.material.set_shader_parameter("active", false)
	

func shake_camera(duration: float = 0.8, intensity: float = 1.) -> void:
	if camera_original_position == Vector3.ZERO: camera_original_position = LevelController.player_camera.position
	camera_shake_duration = duration
	camera_shake_max_duration = duration
	camera_shake_strength = intensity
	
const HIT_FLASH = preload("uid://d12bchhmw3cto")

func apply_hit_flash_shader(object : Node3D, node : Node3D) -> void:
	
	for child in node.get_children():
		if child is MeshInstance3D:
			var original_mat = child.get_active_material(0)

			if original_mat:
				var shader_mat = ShaderMaterial.new()
				shader_mat.shader = HIT_FLASH;
				# Preserve texture if it exists
				if original_mat is StandardMaterial3D:
					shader_mat.set("shader_parameter/albedo_texture", original_mat.albedo_texture)
					child.material_override = shader_mat;
					object.get_flash_module().add_material(shader_mat);
				
			apply_hit_flash_shader(object, child)
	
