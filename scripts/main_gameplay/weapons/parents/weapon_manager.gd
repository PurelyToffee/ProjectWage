class_name WeaponManager extends Node

var weapons: Array[BaseWeapon] = []
var active_weapon_index := -1

func update(delta: float) -> void:
	if active_weapon_index < 0:
		return
	weapons[active_weapon_index].update(delta)

#region Weapon Management

func add_weapon(weapon : BaseWeapon) -> void:
	add_child(weapon)
	weapons.append(weapon);

	if active_weapon_index == -1: set_active_weapon(0);

func add_weapon_by_id(weapon_id: String) -> bool:
	
	if has_weapon(weapon_id):
		return false
		
	if not LevelController.WEAPON_REGISTRY.has(weapon_id):
		return false
		
	var cls = LevelController.WEAPON_REGISTRY[weapon_id]
	add_weapon(cls.new())
	return true

func has_weapon(weapon_id: String) -> bool:
	
	for w in weapons:
		if w.weapon_name == weapon_id:
			return true
			
	return false

func get_weapons() -> Array[BaseWeapon]:
	return weapons;

func set_active_weapon(index: int) -> void:
	if index < 0 or index >= weapons.size():
		return

	if index == active_weapon_index:
		return

	if active_weapon_index >= 0:
		weapons[active_weapon_index].set_equipped(false)

	active_weapon_index = index
	weapons[active_weapon_index].set_equipped(true)

func set_active_weapon_by_name(target_weapon_name: String) -> bool:
	for i in weapons.size():
		if weapons[i].weapon_name == target_weapon_name:
			set_active_weapon(i)
			return true
	return false

func cycle_weapon(dir: int) -> void:
	if weapons.is_empty():
		return
	var new_index = (active_weapon_index + dir) % weapons.size()
	if new_index < 0:
		new_index += weapons.size()
	set_active_weapon(new_index)

#endregion


#region fire and reload

func fire_primary() -> void:
	if active_weapon_index < 0:
		return

	var weapon := weapons[active_weapon_index]
	if weapon.can_fire():
		weapon.fire()

func reload_primary() -> void:
	if active_weapon_index < 0:
		return

	var weapon := weapons[active_weapon_index]
	if weapon.can_reload():
		weapon.reload()

#endregion

func get_active_weapon_state() -> Dictionary:
	if active_weapon_index < 0:
		return {}
		
	return weapons[active_weapon_index].get_ui_state()
