class_name ChainerEnemy extends FloorEnemy

@export var chain : PackedScene;
@export var chain_sphere : PackedScene;
var chain_instance : MeshInstance3D;
var chain_sphere_instance : MeshInstance3D;

@export var chain_start_radius: float = 24.0
@export var chain_min_radius: float = 3.0
@export var chain_shrink_speed: float = 0.1

var current_radius: float
var chain_active: bool = false

func _ready() -> void:
	super._ready()
	
	if is_in_group("telekinesis_target"): remove_from_group("telekinesis_target");

func _on_died() -> void:
	super._on_died()
	
	stop_chain();

func start_follow() -> void:
	super.start_follow();
	
	chain_player();
	
func chain_player() -> void:

	current_radius = chain_start_radius
	chain_active = true

	LevelController.player.add_chain_source(self)
	
	chain_instance = chain.instantiate();
	get_center_point().add_child(chain_instance)
	
	chain_sphere_instance = chain_sphere.instantiate();
	get_center_point().add_child(chain_sphere_instance)

func stop_chain():
	LevelController.player.remove_chain_source(self)
	chain_active = false
	
	chain_instance.queue_free();
	chain_sphere_instance.queue_free();

func _process(delta: float) -> void:
	update_chain(delta);
	update_chain_visual();

func update_chain(delta : float) -> void:
	
	if not chain_active: return
		
	current_radius -= chain_shrink_speed * delta
	current_radius = max(current_radius, chain_min_radius)
	
	chain_sphere_instance.mesh.radius = current_radius;
	chain_sphere_instance.mesh.height = current_radius * 2;
	#chain_sphere_instance.mesh.surface_get_material(0).set_shader_parameter("fade_center", LevelController.player.global_position);

	LevelController.player.add_chain_source(self)

	
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
	
	chain_instance.global_transform = Transform3D(b3, mid)

	var t = clamp(length / current_radius, 0.0, 1.0)
	var mat = chain_instance.get_active_material(0) as StandardMaterial3D
	if mat:
		mat.albedo_color.a = t
		mat.emission_energy_multiplier = t
