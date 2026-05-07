@tool
extends Node3D

@export_range(0.0, 16.0)
var weight := 8.0

@onready var lag_transform := global_transform

var mesh_instances := []

func _ready():
	find_meshes(self)

func find_meshes(node):
	for child in node.get_children():
		if child is MeshInstance3D:
			mesh_instances.append(child)

		find_meshes(child)

func _process(delta):
	lag_transform = lag_transform.interpolate_with(
		global_transform,
		weight * delta
	)

	for mesh in mesh_instances:
		if mesh.material_override:
			mesh.material_override.set_shader_parameter(
				"lag_transform",
				lag_transform
			)
