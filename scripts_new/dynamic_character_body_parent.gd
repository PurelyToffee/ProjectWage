class_name DynamicCharacterBody extends CharacterBody3D

@export var knockback_multiplier := 1.0;
@export var vertical_knockback_multiplier := 1.0;

@export var explosion_knockback_multiplier := 1.0;
@export var explosion_vertical_knockback_multiplier := 1.0;

@onready var health_component: HealthComponent = $HealthComponent

func take_damage(val : float) -> bool:
	return health_component.take_damage(val)

func is_imortal() -> bool:
	return health_component.is_immortal();

func get_center_point() -> Node3D:
	return %CenterPoint;
