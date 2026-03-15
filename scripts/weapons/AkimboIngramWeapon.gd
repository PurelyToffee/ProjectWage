extends "res://scripts/weapons/HitscanWeapon.gd"
class_name AkimboIngramWeapon

func _ready() -> void:
	_apply_weapon_stats()
	ammo = max_ammo

func can_fire() -> bool:
	return super.can_fire() and (infinite_ammo or ammo >= 2)

func can_reload() -> bool:
	return not infinite_ammo and ammo < max_ammo and not _is_reloading()

func reload() -> void:
	_trigger_reload(reload_time)
	print("[Akimbo Ingrams] reloading...")

func _complete_reload() -> void:
	ammo = max_ammo
	print("[Akimbo Ingrams] reload complete")

func fire() -> void:
	_trigger_fire_cooldown(fire_rate)
	_ammo_deduct(2)
	print("[Akimbo Ingrams] fired")
	_shoot_ray()
	_shoot_ray()

func get_ui_state() -> Dictionary:
	var state := super.get_ui_state()
	state["ammo"] = ammo
	state["max_ammo"] = max_ammo
	return state
