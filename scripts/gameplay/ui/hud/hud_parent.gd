class_name HudParent extends Node

@export var hud_drag_elements: Array[Control] = []
@export var hud_rotation_drag: float = 5.0
@export var hud_max_drag_x: float = 20.0
@export var hud_max_drag_y: float = 12.0
@export var hud_weight_min: float = 0.6
@export var hud_weight_max: float = 1.2

var _hud_prev_basis: Basis

func _update_hud_drag(delta: float) -> void:
	var cam = LevelController.player_camera
	var cur_basis: Basis = cam.global_basis
	var rot_delta: Basis = _hud_prev_basis.inverse() * cur_basis
	var euler: Vector3 = rot_delta.get_euler()

	var yaw: float   = euler.y
	var pitch: float = euler.x

	for node in hud_drag_elements:
		var w: float = node.drag_strength

		var target_x = clamp(yaw   * hud_max_drag_x * 100.0 * w, -hud_max_drag_x * w, hud_max_drag_x * w)
		var target_y = clamp(pitch * hud_max_drag_y * 100.0 * w, -hud_max_drag_y * w, hud_max_drag_y * w)

		node.drag_offset.x = lerp(node.drag_offset.x, target_x, hud_rotation_drag * delta)
		node.drag_offset.y = lerp(node.drag_offset.y, target_y, hud_rotation_drag * delta)

		node.drag_offset.x = lerp(node.drag_offset.x, 0.0, hud_rotation_drag * delta * 0.5)
		node.drag_offset.y = lerp(node.drag_offset.y, 0.0, hud_rotation_drag * delta * 0.5)

	_hud_prev_basis = cur_basis

func remove_hud_drag_element(element : GameplayHudElement) -> void:
	
	hud_drag_elements.erase(element);
	

func add_drag_element(element : GameplayHudElement) -> void:
	hud_drag_elements.append(element);
