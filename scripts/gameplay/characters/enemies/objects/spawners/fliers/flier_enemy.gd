class_name FlierEnemy extends FloaterEnemy


var acceleration := Vector3.ZERO;

var max_speed = random.randf_range(8, 12)
var acceleration_strength = random.randf_range(15, 25)

const FLIER_EXPLOSION = preload("uid://dfqy2itscxpwy")

var friendly_explosion := false;


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	
	pass # Replace with function body.


func float_up():
	pass;

func _physics_process(delta: float) -> void:
	super._physics_process(delta);


func get_power_kickable_state() -> bool:
	return dead and !friendly_explosion;

func _on_floating_state_processing(delta: float) -> void:
	
	var direction = LevelController.distance_to_player(get_center_point().global_position).normalized()
	look_at(global_position + direction)
	
	# Desired velocity toward player
	var desired_velocity = direction * max_speed
	
	# Clamp steering force so it doesn't overshoot/orbit
	var steering = (desired_velocity - velocity).limit_length(acceleration_strength)
	
	velocity += steering * delta
	velocity = velocity.limit_length(max_speed)  # Cap max speed

@export var flier_enemy_explosion : PackedScene;
@export var flier_friendly_kick_explosion : PackedScene;
@export var flier_friendly_explosion : PackedScene;

func power_kick() -> void:
	state_set_event(state_chart, "toExplosive")
	friendly_explosion = true;
	
	collision_mask = 0b111;

func get_center_point() -> Node3D:
	return center_point;


func create_explosion(scene : PackedScene) -> void:
		
	var explosion = LevelController.create_scene(scene);
	explosion.global_position = get_center_point().global_position;

func tackle(body : PlayerClass) -> void:
	
	if is_dead() or friendly_explosion : return;
	
	create_explosion(flier_enemy_explosion)
	queue_free();
	
	
func _on_dead_state_processing(delta: float) -> void:

	%MeshInstance3D.get_active_material(0).albedo_color = Color(1, 0, 0);
	
	self.velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta;
	
	if MovementUtils.really_on_floor(self) or is_on_wall():
		
		create_explosion(flier_friendly_explosion)
		queue_free()
	
func _on_explosive_state_processing(delta: float) -> void:
	
	%MeshInstance3D.get_active_material(0).albedo_color = Color(0, 0, 1);
	
	
	self.velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta;
	
	if MovementUtils.really_on_floor(self) or is_on_wall():
		
		create_explosion(flier_friendly_kick_explosion)
		queue_free()
	
	pass # Replace with function body.
