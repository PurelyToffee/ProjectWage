class_name ParentEnemy extends CustomCharacterBody

@onready var world_model: Node3D = %WorldModel
@onready var personal_space_area: Area3D = %PersonalSpaceArea

@export var tackle_damage := 10.0;
@export var tackle_strength := 5.0;

@export var enemy_groups: Array[String] = []


@onready var view_area: Area3D = %ViewArea
@onready var detection_area: Area3D = %DetectionArea

@onready var head_collision: CollisionShape3D = %HeadCollision
@onready var body_collision: CollisionShape3D = %BodyCollision

@onready var attack_origin: Node3D = %AttackOrigin
@onready var attack_offset: Node3D = %AttackOffset
@onready var center_point: Node3D = %CenterPoint

@export var push_force : int = 20;

@export var soft_collide_ignore_groups : Array[String] = [];
var soft_collide := true

var random := RandomNumberGenerator.new()

var power_kickable := false;
var has_been_power_kicked := false;

var can_be_parryed := false;
var has_been_parryed := false;
var open_to_parry := false;

var blown_away : bool = false;
var dead : bool = false;

func _ready() -> void:
	
	
	for group in enemy_groups:
		add_to_group(group)
		
	health_component.holder = self;
	
	health_component.setup(health);
	health_component.connect("died", _on_died)
	
	material_manager_component.collect_standard_materials(world_model);
	material_manager_component.set_holder(self);
	

func check_tackle() -> void:
	
	for body in personal_space_area.get_overlapping_bodies():
		if body.is_in_group("player") :
			tackle(body);
		
	
func tackle(body : PlayerClass) -> void:
	body.take_damage(tackle_damage);
	MovementUtils.apply_knockback(
		body, 
		LevelController.distance_to_player(global_position).normalized(),
		tackle_strength
		)

func get_parryable_state() -> bool:
	return false;

func set_parryable(val : bool = get_parryable_state()) -> void:
	can_be_parryed = val;

func is_parryable() -> bool:
	return can_be_parryed;

func parry() -> void:
	
	if has_been_parryed : return;
	
	has_been_parryed = true;
	pass;
	
func power_kick() -> void:
	pass;
	

func get_center_point() -> Node3D:
	
	return center_point;

func blow_away() -> void:
	blown_away = true;

func is_blown_away() -> bool:
	return blown_away;

func get_material_manager() -> MaterialManagerComponent:
	return material_manager_component;

func basic_enemy_movement(delta : float, flier : bool = false, tackle_damage : bool = false) -> void:
	
	if !flier:
	
		if MovementUtils.really_on_floor(self) : 
			MovementUtils.apply_ground_friction(self, delta);
		else:
			self.velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta;
	
	if tackle_damage: check_tackle();
	if soft_collide : MovementUtils.soft_collide(self, personal_space_area, delta, push_force, soft_collide_ignore_groups)

	if not MovementUtils._snap_up_stairs_check(self, %StairsAheadRayCast3D, delta):
		
		move_and_slide();
		MovementUtils._snap_down_to_stairs_check(self, %StairsBelowRayCast3D, false);

func _physics_process(delta: float) -> void:
	
	set_power_kickable();
	set_parryable()
	
	material_manager_component.set_outline(get_power_kick_outline());
	
	pass;

func get_power_kick_outline() -> bool:
	return is_power_kickable() or is_parryable() and !dead

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


func set_power_kickable(val : bool = get_power_kickable_state()) -> void:
	
	if is_dead() : val = false;
	
	power_kickable = val;
	
	
func get_power_kickable_state() -> bool:
	return false;

func is_power_kickable() -> bool:
	return power_kickable;

func look_at_position(pos : Vector3) -> void:
	look_at(pos, Vector3.UP)	

func _on_died() -> void:
	collision_layer = 0;
	collision_mask = 1

func is_dead() -> bool:
	return dead;

func on_triggered() -> void:
	pass
