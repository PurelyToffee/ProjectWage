class_name BaseWeapon extends Node

@export var weapon_name := "Weapon"

var _equipped := false

func on_equip() -> void:
	_equipped = true

func on_unequip() -> void:
	_equipped = false

func update(_delta: float) -> void:
	pass

func can_fire() -> bool:
	return true

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

func _find_health(node: Node) -> HealthComponent:
	var current := node
	for _i in 3:
		if current.has_node("HealthComponent"):
			return current.get_node("HealthComponent")
		if current.get_parent() != null:
			current = current.get_parent()
		else:
			break
	return null
