extends HitscanWeapon
class_name AkimboIngramWeapon

func _ready() -> void:
	_apply_weapon_stats()
	ammo_per_shot = 2
	ammo = max_ammo

func fire() -> void:
	_trigger_fire_cooldown(fire_rate)
	_ammo_deduct(ammo_per_shot)
	print("[Akimbo Ingrams] fired")
	_shoot_ray()
	_shoot_ray()
