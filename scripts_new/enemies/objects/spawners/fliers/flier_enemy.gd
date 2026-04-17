class_name FlierEnemy extends FloaterEnemy

var acceleration := Vector3.ZERO;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	
	pass # Replace with function body.


func float_up():
	pass;

func _physics_process(delta: float) -> void:
	basic_enemy_movement(delta, false)

func _on_floating_state_processing(delta: float) -> void:
	
	look_at_position(LevelController.get_player_center().global_position)
	
	var direction = LevelController.distance_to_player(get_center_point().global_position).normalized()
	
	var max_speed = 10.0
	var acceleration_strength = 1.0
	
	# Desired velocity toward player
	var desired_velocity = direction * max_speed
	
	# Steering force (this is the key fix)
	var steering = desired_velocity - velocity
	
	velocity += steering * acceleration_strength * delta
	
	
	position += Vector3(0, float_offset, 0) 
	
	pass # Replace with function body.
