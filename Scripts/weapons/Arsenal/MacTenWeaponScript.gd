class_name DualMacTenWeapon extends HitscanWeapon


func _ready() -> void:
	
	fire_rate = 10;
	damage = 10;
	ammo = max_ammo

func fire() -> void:
	#print("[Dual Mac 10] fired")
	fire_shot()
