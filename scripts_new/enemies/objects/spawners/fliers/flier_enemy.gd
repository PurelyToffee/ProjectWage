class_name FlierEnemy extends FloaterEnemy


var acceleration := Vector3.ZERO;

var max_speed = 10.0
var acceleration_strength = random.randf_range(0.2, 0.8);

const FLIER_EXPLOSION = preload("uid://dfqy2itscxpwy")

var friendly_explosion := false;


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	
	pass # Replace with function body.


func float_up():
	pass;

func _physics_process(delta: float) -> void:
	
	set_power_kickable(dead and !friendly_explosion)
	
	material_manager_component.set_outline(get_power_kick_outline());
	
	basic_enemy_movement(delta, true, true);

func _on_floating_state_processing(delta: float) -> void:
	
	var direction = LevelController.distance_to_player(get_center_point().global_position).normalized()
	
	# Desired velocity toward player
	var desired_velocity = direction * max_speed
	
	# Steering force (this is the key fix)
	var steering = desired_velocity - velocity
	
	velocity += steering * acceleration_strength * delta
	
	look_at(global_position + direction)
	
	position += Vector3(0, float_offset, 0) 
	
	pass # Replace with function body.

@export var flier_enemy_explosion : PackedScene;
@export var flier_friendly_explosion : PackedScene;

func power_kick() -> void:
	state_chart.send_event("toExplosive")
	friendly_explosion = true;

func get_center_point() -> Node3D:
	return center_point;


func create_explosion(scene : PackedScene) -> void:
		
	var explosion = LevelController.create_scene(scene);
	explosion.global_position = get_center_point().global_position;

func tackle(body : PlayerClass) -> void:
	
	if friendly_explosion : return;
	
	create_explosion(flier_enemy_explosion)
	queue_free();
	
func _on_explosive_state_processing(delta: float) -> void:
	
	%MeshInstance3D.get_active_material(0).albedo_color = Color(0, 0, 1);
	
	
	self.velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta;
	
	if MovementUtils.really_on_floor(self):
		
		create_explosion(flier_friendly_explosion)
		queue_free()
	
	pass # Replace with function body.
