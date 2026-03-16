class_name BaseWeapon extends Node

@export var headshot_multiplier := 2.0
@export var infinite_ammo := true

var weapon_name := "BaseWeapon"
var fire_rate := 1 #How many shots per second;
var damage := 10.0 #How much damage per shot;
var max_ammo := 30 #How many bullets;
var spread := 0.0 #Spread;
var fire_range := 50.0 #Max range of bullets;
var reload_time := 1.5 #Reload time in seconds;
var ammo_per_shot := 1
var ammo := max_ammo

var reloading := false;
var equipped := false
var fire_cooldown := 0.0
var reload_cooldown := 0.0

func set_equipped(val : bool) -> void:
	equipped = val;

func update(delta: float) -> void:
	
	fire_cooldown = max(fire_cooldown - delta, 0)
	reload_cooldown = max(reload_cooldown - delta, 0)
		
	if reload_cooldown == 0.0 and reloading: complete_reload()

#region firing

func can_fire() -> bool:
	return is_fire_ready() and not is_reloading() and (infinite_ammo or ammo >= ammo_per_shot)

func fire() -> void:
	pass
	
func reduce_ammo(bullets = 1) -> void:
	if ammo <= 0 or infinite_ammo:
		return
	ammo -= bullets

func is_fire_ready() -> bool:
	return fire_cooldown <= 0.0

func set_fire_cooldown(duration: float) -> void:
	fire_cooldown = 1./duration

#endregion

#region reload

func can_reload() -> bool:
	return not infinite_ammo and ammo < max_ammo and not is_reloading()

func reload() -> void:
	trigger_reload(reload_time)
	print("[", weapon_name, "] reloading...")

func is_reloading() -> bool:
	return reloading;

func trigger_reload(duration: float) -> void:
	if reloading : return
	
	reloading = true;
	reload_cooldown = duration

func complete_reload() -> void:
	ammo = max_ammo
	reloading = false;
	print("[", weapon_name, "] reload complete")

#endregion

func get_ui_state() -> Dictionary:
	return {
		"weapon_name": weapon_name,
		"ammo": ammo,
		"max_ammo": max_ammo
	}
