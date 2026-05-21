class_name PistolWeapon extends HitscanWeapon

func _ready() -> void:

	weapon_name = "Pistol"
	fire_rate = 3
	damage = 100
	ammo = max_ammo
	spread = 0.0
	knockback_force = 6
	knockback_vertical_bonus = 0.4
