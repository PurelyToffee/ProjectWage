class_name DualMacTenWeapon extends HitscanWeapon


func _ready() -> void:
	
	fire_rate = 10;
	damage = 10;
	ammo = max_ammo

func fire() -> void:
	set_fire_cooldown(fire_rate)
	reduce_ammo(ammo_per_shot)
	print("[Dual Mac 10] fired")
	fire_shot()
