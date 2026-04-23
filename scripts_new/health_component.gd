class_name HealthComponent extends Node

@export var max_hp: float : set = set_max, get = get_max;
@export var immortal: bool : set = set_immortal, get = is_immortal;
var hp: float : set = set_health, get = get_health;

var resistances = {};

var dead := false;

var invulnerability := 0;
@onready var holder : CustomCharacterBody = get_parent();
signal died()

func _process(delta: float) -> void:
	invulnerability = maxf(invulnerability - delta, 0.);
	

func setup(init_hp: float = 100, init_immortal: bool = false):
	
	dead = false;
	max_hp = init_hp
	immortal = init_immortal
	invulnerability = 0
	hp = init_hp
	resistances.clear()

func take_damage(amount: float) -> bool:
	if (amount < 0):
		return false;

	if holder and holder.has_method("get_material_manager"):
		holder.get_material_manager().flash();

	for val in resistances.values():
		amount *= val;

	hp -= amount 
	
	return hp <= 0; #Returns if object died or not;

func set_resistance(key : String, val : float) -> void:
	resistances[key] = val;

func heal(amount: float):
	if (amount < 0):
		return
	hp += amount

func set_max(val: float):
	max_hp = clampf(val, 0, INF);
	if hp > max_hp:
		var temp: bool = immortal;
		immortal = false;
		hp = max_hp;
		immortal = temp;
	return

func get_max():
	return max_hp

func set_health(val: float):
	if (is_immortal() and val < hp):
		return
		
	hp = clampf(val, 0, max_hp);
	if hp >= 0 and dead:
		dead = false;
	
	if hp <= 0 and !dead:
		died.emit();
		dead = true;
	return

func get_health():
	return hp

func set_immortal(val: bool):
	immortal = val;

func set_invulnerability(val : float) -> void:
	invulnerability = val;

func is_immortal():
	return immortal or invulnerability > 0.;
