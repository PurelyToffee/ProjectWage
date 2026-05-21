class_name GameplayHudElement extends Control

@export var drag_strength  := 0.5
@export var shake_duration := 0.5

var shake_strength := 0.0
var shake_elapsed  := 0.0
var shaking        := false

var origin       : Vector2 = Vector2.ZERO
var drag_offset  : Vector2 = Vector2.ZERO
var shake_offset : Vector2 = Vector2.ZERO

var use_global_positioning := true

func _ready() -> void:
	if use_global_positioning:
		origin = global_position

func set_origin(pos: Vector2) -> void:
	origin = pos

func apply_offsets() -> void:
	if use_global_positioning:
		global_position = origin + drag_offset + shake_offset
	else:
		position = drag_offset + shake_offset

func shake(strength: float) -> void:
	shake_strength = strength
	shake_elapsed  = 0.0
	shaking        = true

func _process(delta: float) -> void:
	if shaking:
		shake_elapsed += delta
		if shake_elapsed >= shake_duration:
			shaking      = false
			shake_offset = Vector2.ZERO
		else:
			var strength = shake_strength * (1.0 - (shake_elapsed / shake_duration))
			shake_offset = Vector2(
				randf_range(-strength, strength),
				randf_range(-strength, strength)
			)
	apply_offsets()
