class_name floor_enemy extends ParentEnemy

var target : Node3D;

var follow_speed : float = 6;
var last_frame_position := global_position;
var stuck_counter : int = 0;

const MAX_STEP_HEIGHT = 0.5;
var _snapped_to_stairs_last_frame := false
var _last_frame_was_on_floor := -INF

func _ready() -> void:
	super._ready();
	
	safe_margin = 0.05
	
	target = get_tree().get_first_node_in_group("player")
	
	%NavigationAgent3D.velocity_computed.connect(_on_velocity_computed);
	
func _physics_process(delta: float) -> void:
	
	super._physics_process(delta);
	
	if MovementUtils.really_on_floor(self):
		
		MovementUtils.apply_ground_friction(self, delta);
		
		if  !%NavigationAgent3D.is_navigation_finished():
			if stuck_counter >= 5:
				self.velocity.y += 2;
				stuck_counter = 0;
			else:
				var val := 0;
				if last_frame_position == global_position : 
					blown_away = false;
					val = 1;
					
				stuck_counter = (stuck_counter + val) * val;
				last_frame_position = global_position
		
	else:
		self.velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta;
		
	
	if not MovementUtils._snap_up_stairs_check(self, %StairsAheadRayCast3D, delta):
	
		move_and_slide();
		MovementUtils._snap_down_to_stairs_check(self, %StairsBelowRayCast3D, false);

func _on_died() -> void:
	queue_free()
	
func _on_velocity_computed(safe_velocity : Vector3) -> void:
	
	if blown_away: return
	
	velocity.x = safe_velocity.x
	velocity.z = safe_velocity.z
	

func _on_follow_state_physics_processing(delta: float) -> void:

	if not target:
		return
		
	%NavigationAgent3D.target_position = target.global_position
	
	if %NavigationAgent3D.is_navigation_finished():
		%NavigationAgent3D.velocity = Vector3.ZERO
		return
		
	var next_pos = %NavigationAgent3D.get_next_path_position()
	var direction = (next_pos - global_position).normalized()
	
	%NavigationAgent3D.velocity = direction * follow_speed;

	
	if blown_away :
		look_at(global_position + MovementUtils.get_horizontal_vector(-self.velocity), Vector3.UP)
	else:
		look_at(global_position + MovementUtils.get_horizontal_vector(%NavigationAgent3D.velocity), Vector3.UP)
		
	pass # Replace with function body.

func _on_triggered() -> void:
	pass

func _on_detection_area_body_entered(body: Node3D) -> void:

	
	if body.is_in_group("player"):
		%StateChart.send_event("toFollow")


func _on_view_area_body_exited(body: Node3D) -> void:
	

	if body.is_in_group("player"):
		
		%StateChart.send_event("toIdle")
		stop_navigation();

func start_navigation() -> void:

	%NavigationAgent3D.target_position = target.global_position;

func stop_navigation() -> void:
	%NavigationAgent3D.velocity = Vector3.ZERO
	velocity = Vector3.ZERO
	%NavigationAgent3D.target_position = global_position
