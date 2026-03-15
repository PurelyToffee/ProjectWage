class_name AkimboIngramWeapon extends HitscanWeapon

const FIRE_RATE  := 0.07   # both guns fire together
const DAMAGE     := 8.0    # per bullet, 2 bullets per burst
# const MAX_AMMO   := 60     # 30 rounds per gun
const SPREAD     := 0.05   # radians of random spread
const RANGE      := 40.0   # meters :3

func _ready() -> void:
	weapon_name = "Akimbo Ingrams"

func can_fire() -> bool:
	return _is_fire_ready() # and ammo >= 2

func fire() -> void:
	_trigger_fire_cooldown(FIRE_RATE)
	# ammo -= 2
	print("[Akimbo Ingrams] fired")
	_shoot_ray(DAMAGE, SPREAD, RANGE)
	_shoot_ray(DAMAGE, SPREAD, RANGE)

func get_ui_state() -> Dictionary:
	var state := super.get_ui_state()
	# state["ammo"] = ammo
	# state["max_ammo"] = MAX_AMMO
	return state
