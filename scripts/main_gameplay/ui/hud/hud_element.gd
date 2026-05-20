class_name GameplayHudElement extends Control

@export var drag_strength := 0.5;

@export var shake_duration := 0.5
@export var shake_decay := 5.0

var shake_strength := 0.0
var shake_elapsed := 0.0
var shaking := false
var origin: Vector2

func shake(strength: float):
	shake_strength = strength
	origin = position
	shake_elapsed = 0.0
	shaking = true

func _process(delta: float):
	if not shaking:
		return

	shake_elapsed += delta
	if shake_elapsed >= shake_duration:
		shaking = false
		position = origin
		return

	var strength = shake_strength * (1.0 - (shake_elapsed / shake_duration))
	position = origin + Vector2(
		randf_range(-strength, strength),
		randf_range(-strength, strength)
	)
