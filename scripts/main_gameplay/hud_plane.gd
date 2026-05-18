class_name HudPlane
extends MeshInstance3D

@export var viewport: SubViewport

func _ready() -> void:
	var mat := StandardMaterial3D.new()

	mat.albedo_texture = viewport.get_texture()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	set_surface_override_material(0, mat)
