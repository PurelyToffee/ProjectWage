class_name BaseWeapon extends Node

@export var weapon_name := "Weapon"
@export var headshot_multiplier := 2.0

var _equipped := false
var _fire_cooldown := 0.0

func on_equip() -> void:
	_equipped = true

func on_unequip() -> void:
	_equipped = false

func update(delta: float) -> void:
	if _fire_cooldown > 0.0:
		_fire_cooldown -= delta

func can_fire() -> bool:
	return _is_fire_ready()

func fire() -> void:
	pass

# func can_reload() -> bool:
# 	return false
#
# func reload() -> void:
# 	pass

func get_ui_state() -> Dictionary:
	return {
		"weapon_name": weapon_name
	}

func _resolve_damage(base: float, is_headshot: bool) -> float:
	return base * headshot_multiplier if is_headshot else base

func _is_fire_ready() -> bool:
	return _fire_cooldown <= 0.0

func _trigger_fire_cooldown(duration: float) -> void:
	_fire_cooldown = duration
