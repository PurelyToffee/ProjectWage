class_name WeaponManager extends Node

var _weapons: Array[BaseWeapon] = []
var _active_weapon_index := -1

func _ready() -> void:
	_collect_weapons()
	if _weapons.size() > 0:
		_set_active_weapon(0)

func _collect_weapons() -> void:
	_weapons.clear()
	for child in get_children():
		if child is BaseWeapon:
			_weapons.append(child)

func update(delta: float) -> void:
	if _active_weapon_index < 0:
		return
	_weapons[_active_weapon_index].update(delta)

func fire_primary() -> void:
	if _active_weapon_index < 0:
		return

	var weapon := _weapons[_active_weapon_index]
	if weapon.can_fire():
		weapon.fire()

func reload_primary() -> void:
	if _active_weapon_index < 0:
		return

	var weapon := _weapons[_active_weapon_index]
	if weapon.can_reload():
		weapon.reload()

func set_active_weapon_by_name(target_weapon_name: String) -> bool:
	for i in _weapons.size():
		if _weapons[i].weapon_name == target_weapon_name:
			_set_active_weapon(i)
			return true
	return false

func get_active_weapon_state() -> Dictionary:
	if _active_weapon_index < 0:
		return {}
	return _weapons[_active_weapon_index].get_ui_state()

func _set_active_weapon(index: int) -> void:
	if index < 0 or index >= _weapons.size():
		return

	if _active_weapon_index >= 0:
		_weapons[_active_weapon_index].on_unequip()

	_active_weapon_index = index
	_weapons[_active_weapon_index].on_equip()
