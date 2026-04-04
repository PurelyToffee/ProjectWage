class_name ChainerEnemy extends FloorEnemy

@export var chain_start_radius: float = 24.0
@export var chain_min_radius: float = 3.0
@export var chain_shrink_speed: float = 0.5
@onready var chain_mesh: MeshInstance3D = %ChainMesh

var current_radius: float
var chain_active: bool = false

func start_follow() -> void:
	super.start_follow();
	
	chain_player();
	
func chain_player() -> void:

	current_radius = chain_start_radius
	chain_active = true

	LevelController.player.add_chain_source(self)


func _process(delta: float) -> void:
	update_chain(delta);
	update_chain_visual();

func update_chain(delta : float) -> void:
	
	if not chain_active: return
		
	current_radius -= chain_shrink_speed * delta
	current_radius = max(current_radius, chain_min_radius)

	LevelController.player.add_chain_source(self)

func stop_chain():
	LevelController.player.clear_chain()
	chain_active = false
	
	
func update_chain_visual():
	if not chain_active:
		return
		
	var a = get_center_point().global_position
	var b = LevelController.player.global_position
	
	var dir = b - a
	var length = dir.length()
	var forward = dir.normalized()
	
	var mid = (a + b) * 0.5
	var cam_pos = LevelController.player_camera.global_position
	var to_cam = (cam_pos - mid).normalized()
	
	var up = forward.cross(to_cam)
	if up.length() < 0.001:
		up = forward.cross(Vector3.UP)
	up = up.normalized()
	
	var normal = forward.cross(up).normalized()
	
	var b3 = Basis()
	b3.x = forward * length  
	b3.y = up                
	b3.z = normal            
	
	chain_mesh.global_transform = Transform3D(b3, mid)

	var t = clamp(length / current_radius, 0.0, 1.0)  # 0 = close, 1 = at full radius
	
	var mat = chain_mesh.get_active_material(0) as StandardMaterial3D
	if mat:
		mat.albedo_color.a = t
		mat.emission_energy_multiplier = t
