class_name CameraComponent extends Node

var camera : Camera3D;
var camera_smooth : Node3D
var camera_tilt : Node3D

var camera_tilt_target : float = 0.;

const HEADBOB_MOVE_AMMOUNT := 0.06;
const HEADBOB_FREQUENCY := 2.4;
var headbob_time := 0.;


func update(delta: float) -> void:
	
	camera_tilt.rotation.z = lerp(camera_tilt.rotation.z, camera_tilt_target, 10 * delta);
	
	pass

func set_camera_tilt(val : float) -> void:
	camera_tilt_target = val;

func _headbob_effect(delta: float, speed : float):
	
	headbob_time += delta * speed;
	
	camera.transform.origin = Vector3(
		cos(headbob_time * HEADBOB_FREQUENCY * 0.5) * HEADBOB_MOVE_AMMOUNT,
		sin(headbob_time * HEADBOB_FREQUENCY) * HEADBOB_MOVE_AMMOUNT,
		0
	)
	
	pass

func rotate_x(x_ : float, min = -INF, max = INF) -> void:
	
	camera.rotate_x(x_);
	camera.rotation.x = clamp(camera.rotation.x, min, max)
	
func rotate_y(y_ : float, min = -INF, max = INF) -> void:
	
	camera.rotate_y(y_);
	camera.rotation.y = clamp(camera.rotation.y, min, max)
	
func rotate_z(z_ : float, min = -INF, max = INF) -> void:
	
	camera.rotate_x(z_);
	camera.rotation.z = clamp(camera.rotation.z, min, max)
	

func set_x_rotation(x_ : float) -> void:
	camera.rotation.x = x_;
	
func set_y_rotation(y_ : float) -> void:
	camera.rotation.y = y_;
	
func set_z_rotation(z_ : float) -> void:
	camera.rotation.z = z_;
	
	
var _saved_camera_global_pos = null
func _save_camera_pos_for_smoothing():
	if _saved_camera_global_pos == null:
		_saved_camera_global_pos = camera_smooth.global_position

func _slide_camera_smooth_back_to_origin(delta : float, speed : float, walk_speed : float):
	if _saved_camera_global_pos == null: return
	
	camera_smooth.global_position.y = _saved_camera_global_pos.y
	camera_smooth.position.y = clampf(camera_smooth.position.y, -0.7, 0.7) # Clamp incase teleported
	var move_amount = max(speed * delta, walk_speed/2 * delta)
	
	camera_smooth.position.y = move_toward(camera_smooth.position.y, 0.0, move_amount)
	_saved_camera_global_pos = camera_smooth.global_position
	
	if camera_smooth.position.y == 0:
		_saved_camera_global_pos = null # Stop smoothing camera
