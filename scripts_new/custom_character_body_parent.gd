class_name CustomCharacterBody extends CharacterBody3D

@onready var health_component: HealthComponent = $HealthComponent
@onready var material_manager_component: MaterialManagerComponent = $MaterialManagerComponent

@export var health : float = 100.0;
@export var ground_accel := 14.0;
@export var ground_deccel := 10.0;
@export var ground_friction := 6.0;

@export var score_award := 30.;


@export var knockback_multiplier := 1.0;
@export var vertical_knockback_multiplier := 1.0;

@export var explosion_knockback_multiplier := 1.0;
@export var explosion_vertical_knockback_multiplier := 1.0;


const MAX_STEP_HEIGHT = 0.5;
var _snapped_to_stairs_last_frame := false
var _last_frame_was_on_floor := -INF

func take_damage(val : float) -> bool:
	return health_component.take_damage(val)

func get_health() -> float:
	return health_component.get_health();
	
func is_immortal() -> bool:
	return health_component.is_immortal();

func get_material_manager() -> MaterialManagerComponent:
	return material_manager_component;
	
func get_center_point() -> Node3D:
	return %CenterPoint;

func kill() -> void:
	take_damage(100000000);
