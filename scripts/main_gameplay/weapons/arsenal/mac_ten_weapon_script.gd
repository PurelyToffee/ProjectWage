class_name DualMacTenWeapon extends HitscanWeapon

func _ready() -> void:
	
	weapon_name = "DualMac10"
	index = LevelController.WEAPONS.DMacTen
	fire_rate = 10;
	damage = 15;
	ammo = max_ammo
	knockback_force = 3
	knockback_vertical_bonus = 0;
