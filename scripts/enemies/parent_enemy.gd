class_name ParentEnemy extends CharacterBody3D

@onready var attack_origin: Node3D = $AttackOrigin

@export var enemy_groups: Array[String] = []
@export var ground_accel = 14.0;
@export var ground_deccel = 10.0;
@export var ground_friction := 6.0;

var blown_away : bool = false;
var dead : bool = false;

func _ready() -> void:
	
	for group in enemy_groups:
		add_to_group(group)
		
		
func get_center_point() -> Node3D:
	
	return %CenterPoint if !dead else null;

func blow_away() -> void:
	blown_away = true;

func is_blown_away() -> bool:
	return blown_away;

func _physics_process(delta: float) -> void:
	pass;


func on_triggered() -> void:
	pass
