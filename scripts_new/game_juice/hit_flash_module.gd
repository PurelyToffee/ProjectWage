class_name MaterialManagerComponent extends Node

var mesh_materials = [];

@export var outline_material : StandardMaterial3D;

func add_material(mat : Material) -> void:
	mat.emission_enabled = true;
	mesh_materials.append(mat);

func collect_standard_materials(node):
	for child in node.get_children():
		
		if child is MeshInstance3D:
			# Duplicate material so each mesh can flash independently
			if child.get_active_material(0) is StandardMaterial3D:
				var mat = child.get_active_material(0).duplicate()
				child.set_surface_override_material(0, mat)
				add_material(mat)
				
		collect_standard_materials(child)


func flash() -> void:
	var tween = create_tween()
	tween.tween_method(set_flash, 0.0, 1.0, 0.08)
	tween.tween_method(set_flash, 1.0, 0.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
func set_flash(value: float):
	for mat in mesh_materials:
		mat.emission = Color(1, 1, 1)
		mat.emission_energy = value * 5.0  # scale intensity


func set_outline(val : bool = false) -> void:
	
	for mat : StandardMaterial3D in mesh_materials:
		mat.next_pass = outline_material if val else null;
