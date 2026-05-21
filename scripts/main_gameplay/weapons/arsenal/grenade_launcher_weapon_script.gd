class_name GrenadeLauncherWeapon extends ProjectileWeapon

const GRENADE_SCENE = preload("res://scripts/main_gameplay/grenade/player_grenade.tscn")

var grenade_max_bounces := 5
var grenade_damage_multiplier := 2.0
var grenade_base_damage := 50.0
var grenade_fuse_seconds := 3.0

func _ready() -> void:

	weapon_name = "GrenadeLauncher"
	index = LevelController.WEAPONS.GLauncher
	fire_rate = 1
	damage = grenade_base_damage
	max_ammo = 6
	ammo = max_ammo
	reload_time = 2.0
	ammo_per_shot = 1

	projectile_scene = GRENADE_SCENE
	launch_speed = 30.0

func _configure_projectile(projectile) -> void:
	var grenade : PlayerGrenade = projectile
	grenade.max_bounces = grenade_max_bounces
	grenade.damage_multiplier_per_bounce = grenade_damage_multiplier
	grenade.base_damage = grenade_base_damage
	grenade.fuse_seconds = grenade_fuse_seconds
