class_name ParentEnemy extends CharacterBody3D

@onready var health_component: HealthComponent = $HealthComponent
@onready var hit_flash_module: HitFlashModule = $HitFlashModule
@onready var world_model: Node3D = %WorldModel



@onready var attack_origin: Node3D = $AttackOrigin

@export var enemy_groups: Array[String] = []
@export var ground_accel = 14.0;
@export var ground_deccel = 10.0;
@export var ground_friction := 6.0;

@export var score_award := 30.;

@onready var view_area: Area3D = %ViewArea
@onready var detection_area: Area3D = %DetectionArea

@onready var head_collision: CollisionShape3D = %HeadCollision
@onready var body_collision: CollisionShape3D = %BodyCollision

var can_be_parryed := true;
var has_been_parryed := false;
var open_to_parry := false;

var blown_away : bool = false;
var dead : bool = false;

func _ready() -> void:
	
	for group in enemy_groups:
		add_to_group(group)
		
	health_component.holder = self;
	hit_flash_module.collect_standard_materials(world_model);
		

func set_parryable(val : bool = true) -> void:
	can_be_parryed = val;

func is_parryable() -> bool:
	return can_be_parryed;

func is_open_to_parry() -> bool:
	return open_to_parry;

func set_open_to_parry(val : bool = true) -> void:
	open_to_parry = val; 

func parry() -> void:
	
	if has_been_parryed : return;
	
	has_been_parryed = true;
	pass;

func get_center_point() -> Node3D:
	
	return %CenterPoint if !dead else null;

func blow_away() -> void:
	blown_away = true;

func is_blown_away() -> bool:
	return blown_away;

func get_flash_module() -> HitFlashModule:
	return hit_flash_module;

func _physics_process(delta: float) -> void:
	pass;

func inside_detection(target : String = "player") -> bool:
	
	for body in detection_area.get_overlapping_bodies():
		if !body.is_in_group(target): continue;
		
		return true;
		
	return false;
	
func inside_view(target : String = "player") -> bool:
	
	for body in view_area.get_overlapping_bodies():
		if !body.is_in_group(target): continue;
		
		return true;
		
	return false;


func _on_died() -> void:
	collision_mask = 1

func is_dead() -> bool:
	return dead;

func on_triggered() -> void:
	pass
