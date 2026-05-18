class_name HudCamera extends Camera3D
@onready var hud_plane_left: MeshInstance3D = %HudPlaneLeft


func _ready() -> void:
	var distance = 1.0
	var size = get_quad_size_at_distance(distance)
	
	var quad = hud_plane_left.mesh as PlaneMesh
	quad.size = size
	
	hud_plane_left.position = Vector3(0, 0, -distance)

func get_quad_size_at_distance(distance: float) -> Vector2:
	var half_fov = deg_to_rad(fov / 2.0)
	var height = 2.0 * distance * tan(half_fov)
	
	var width = height * (float(get_viewport().size.x) / float(get_viewport().size.y))
	return Vector2(width, height)
