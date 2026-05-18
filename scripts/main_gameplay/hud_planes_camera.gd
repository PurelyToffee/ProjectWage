class_name HudCamera extends Camera3D

@export var rotation_drag: float = 5.0   # higher = snappier
@export var depth_drag: float = 5.0      # higher = snappier
@export var depth_scale: float = 0.2     # how much forward/back movement affects depth
@export var max_drag : float = 0.1;


@export var right_planes: Array[HudPlane] = []
@export var middle_planes: Array[HudPlane] = []
@export var left_planes: Array[HudPlane] = []

var all_planes := []

@onready var left_hud_plane: HudPlane = %LeftHudPlane

var _prev_cam_basis: Basis
var _prev_cam_pos: Vector3
var _plane_base_dist: Dictionary = {}  # HudPlane -> base Z distance
var _prev_player_pos: Vector3

func _ready() -> void:
	all_planes.append_array(right_planes)
	all_planes.append_array(left_planes)
	all_planes.append_array(middle_planes)

	for plane in all_planes:
		fit_hud_plane(plane)
		_plane_base_dist[plane] = plane.position.z

	var cam = LevelController.player_camera
	_prev_cam_basis = cam.global_basis
	_prev_cam_pos = cam.global_position
	_prev_player_pos = LevelController.player.global_position

@export var max_drag_x: float = 0.5
@export var max_drag_y: float = 0.3

func _physics_process(delta: float) -> void:
	var cam = LevelController.player_camera
	var player = LevelController.player

	# --- Rotation drag (local X/Y position lag) ---
	var cur_basis: Basis = cam.global_basis
	var rot_delta: Basis = _prev_cam_basis.inverse() * cur_basis
	var euler: Vector3 = rot_delta.get_euler()
	var yaw: float = euler.y
	var pitch: float = euler.x

	# --- Depth drag (forward/back movement, rotation-independent) ---
	var cam_forward: Vector3 = -cam.global_basis.z
	var move: Vector3 = player.global_position - _prev_player_pos
	var forward_movement: float = cam_forward.dot(move)

	for plane in all_planes:
		var base_z: float = _plane_base_dist[plane]
		var target_z: float = forward_movement * depth_scale * 10.0
		
		print(target_z)
		target_z = clamp(target_z, -max_drag, max_drag)
		plane.position.z = lerp(plane.position.z, base_z + target_z, depth_drag * delta)
		plane.position.z = lerp(plane.position.z, base_z, depth_drag * delta * 0.5)

	_prev_cam_basis = cur_basis
	_prev_cam_pos = cam.global_position
	_prev_player_pos = player.global_position

func rotate_left_planes(val: float) -> void:
	for plane in left_planes:
		var half_width: float = plane.texture.get_width() * plane.pixel_size / 2.0
		plane.position.x -= half_width
		plane.rotate_y(val)
		plane.position.x += half_width * cos(val)
		plane.position.z -= half_width * sin(val)

func rotate_right_planes(val: float) -> void:
	for plane in right_planes:
		var half_width: float = plane.texture.get_width() * plane.pixel_size / 2.0
		plane.position.x += half_width
		plane.rotate_y(val)
		plane.position.x -= half_width * cos(val)
		plane.position.z += half_width * sin(val)

func fit_hud_plane(plane: HudPlane) -> void:
	var sprite_size: Vector2 = Vector2(plane.texture.get_width(), plane.texture.get_height()) * plane.pixel_size
	var aspect: float = sprite_size.x / sprite_size.y
	var cam_aspect: float = get_viewport().get_visible_rect().size.x / get_viewport().get_visible_rect().size.y
	var fov_rad: float = deg_to_rad(fov)
	var dist: float
	if aspect >= cam_aspect:
		var h_fov: float = 2.0 * atan(tan(fov_rad / 2.0) * cam_aspect)
		dist = (sprite_size.x / 2.0) / tan(h_fov / 2.0)
	else:
		dist = (sprite_size.y / 2.0) / tan(fov_rad / 2.0)
	plane.position = Vector3(0.0, 0.0, -dist)
