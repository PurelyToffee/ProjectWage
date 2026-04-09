class_name DynamicCharacterBody extends CharacterBody3D

@export var knockback_multiplier := 1.0;
@onready var health_component: HealthComponent = $HealthComponent

func take_damage(val : float) -> bool:
	return health_component.take_damage(val)


func get_center_point() -> Node3D:
	return %CenterPoint;
