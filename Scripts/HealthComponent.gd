class_name HealthComponent extends Node

@export var max_hp: float : set = set_max, get = get_max;
@export var immortal: bool : set = set_immortal, get = is_immortal;
@onready var hp: float : set = set_hp, get = get_hp;

signal died()

func _init():
	setup()

func setup(init_hp: float = 100, init_immortal: bool = false):
	max_hp = init_hp
	hp = init_hp
	immortal = init_immortal

func take_damage(amount: float):
	if (amount < 0):
		return
	hp -= amount

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

func set_hp(val: float):
	if (immortal and val < hp):
		return
	hp = clampf(val, 0, max_hp);
	if hp <= 0:
		died.emit();
	return

func get_hp():
	return hp

func set_immortal(val: bool):
	immortal = val;

func is_immortal():
	return immortal;
