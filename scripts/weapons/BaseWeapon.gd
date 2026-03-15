class_name BaseWeapon extends Node

var weapon_name := "Weapon"
@export var headshot_multiplier := 2.0
var fire_rate := 0.5
var damage := 10.0
var max_ammo := 30
var spread := 0.0
var fire_range := 50.0
var reload_time := 1.5
@export var weapon_stats: WeaponStats
@export var infinite_ammo := true
var ammo_per_shot := 1

var _equipped := false
var _fire_cooldown := 0.0
var _reload_cooldown := 0.0
var ammo := 0

func _ready() -> void:
	_apply_weapon_stats()
	ammo = max_ammo

func _apply_weapon_stats() -> void:
	if weapon_stats == null:
		return

	weapon_name = weapon_stats.weapon_name
	fire_rate = weapon_stats.fire_rate
	damage = weapon_stats.damage
	max_ammo = weapon_stats.max_ammo
	spread = weapon_stats.spread
	fire_range = weapon_stats.fire_range
	reload_time = weapon_stats.reload_time

func on_equip() -> void:
	_equipped = true

func on_unequip() -> void:
	_equipped = false

func update(delta: float) -> void:
	if _fire_cooldown > 0.0:
		_fire_cooldown -= delta
	if _reload_cooldown > 0.0:
		_reload_cooldown -= delta
		if _reload_cooldown <= 0.0:
			_reload_cooldown = 0.0
			_complete_reload()

func can_fire() -> bool:
	return _is_fire_ready() and not _is_reloading() and (infinite_ammo or ammo >= ammo_per_shot)

func fire() -> void:
	pass
	
func _ammo_deduct(bullets = 1) -> void:
	if ammo <= 0 or infinite_ammo:
		return
	ammo -= bullets

func can_reload() -> bool:
	return not infinite_ammo and ammo < max_ammo and not _is_reloading()

func reload() -> void:
	_trigger_reload(reload_time)
	print("[", weapon_name, "] reloading...")

func _is_reloading() -> bool:
	return _reload_cooldown > 0.0

func _trigger_reload(duration: float) -> void:
	if _is_reloading():
		return
	_reload_cooldown = duration

func _complete_reload() -> void:
	ammo = max_ammo
	print("[", weapon_name, "] reload complete")

func get_ui_state() -> Dictionary:
	return {
		"weapon_name": weapon_name,
		"ammo": ammo,
		"max_ammo": max_ammo
	}

func _is_fire_ready() -> bool:
	return _fire_cooldown <= 0.0

func _trigger_fire_cooldown(duration: float) -> void:
	_fire_cooldown = duration
