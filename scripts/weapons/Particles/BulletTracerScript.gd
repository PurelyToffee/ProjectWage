extends Node3D

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
var cylinder : CylinderMesh;

var life := 0.4
var t := 0.0
var radius := 0.04

func _ready() -> void:
	cylinder = mesh_instance.mesh;

func fire(start: Vector3, end: Vector3):

	var dir = end - start
	var dist = dir.length()
	dir = dir.normalized()

	# place cylinder midpoint
	global_position = start

	# rotate so the cylinder's Y axis points along the ray
	transform.basis = Basis().looking_at(dir, Vector3.UP) * Basis(Vector3.RIGHT, deg_to_rad(90))
	mesh_instance.position = Vector3(0, -dist * 0.5, 0)

		# set initial mesh dimensions
	cylinder.height = dist
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius

func _process(delta):

	t += delta
	var progress = t / life

	if progress >= 1:
		queue_free()
		return

	var r = radius * (1.0 - progress)

	cylinder.top_radius = r
	cylinder.bottom_radius = r
