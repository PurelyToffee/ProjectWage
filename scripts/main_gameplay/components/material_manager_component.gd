class_name MaterialManagerComponent
extends Node

var mesh_materials = []
var smear_materials = []
var smear_meshes = []  # add this alongside smear_materials
var outline_meshes = []
var default_colors : Array[Color] = []

@export var outline_material : StandardMaterial3D = preload("uid://yoqn810qk2fb")
@export var smear_shader : Shader = preload("uid://b3krcvb74hh5")
@export var noise_texture : Texture2D = preload("uid://bnn45uwfynrl5")

@export var outline_shader : Shader = preload("uid://cqkt4dbx710lg")
@export var outline_color : Color = Color.YELLOW
@export_range(0.0, 0.1) var outline_width := 0.02

@export_group("Motion Smear")
@export var enable_motion_smear := true
@export_range(0.0, 16.0)
var smear_weight := 8.0

var lag_transform : Transform3D
var duplicated := false

var holder : CustomCharacterBody

var _outline_material : ShaderMaterial = preload("uid://mankuowtpvdy")

func _ready() -> void:
	holder = get_parent()
	lag_transform = holder.global_transform

	collect_materials(holder)


func _process(delta: float) -> void:

	if !enable_motion_smear:
		return

	lag_transform = lag_transform.interpolate_with(
		holder.global_transform,
		smear_weight * delta
	)

	for i in smear_materials.size():
		var smear = smear_materials[i]
		var base = mesh_materials[i] if i < mesh_materials.size() else null

		if smear:
			smear.set_shader_parameter("lag_transform", lag_transform)
			smear.set_shader_parameter("current_transform", holder.global_transform)
			if base:
				smear.set_shader_parameter("albedo_color", base.albedo_color)


func set_holder(object : CustomCharacterBody) -> void:
	holder = object


func collect_materials(node: Node) -> void:

	for child in node.get_children():

		if child is MeshInstance3D:
			setup_mesh(child)

		collect_materials(child)


const SMEAR_GROUP = "smear_mesh"

func setup_mesh(mesh: MeshInstance3D) -> void:

	if mesh.is_in_group(SMEAR_GROUP):
		return

	var base_material = mesh.get_active_material(0)
	if base_material == null:
		return

	var duplicated_base = base_material.duplicate(true)
	var initial_color := Color.WHITE

	if duplicated_base is StandardMaterial3D:
		duplicated_base.emission_enabled = true
		initial_color = duplicated_base.albedo_color
		mesh_materials.append(duplicated_base)
		default_colors.append(initial_color)

	mesh.set_surface_override_material(0, duplicated_base)

	var smear_mesh := MeshInstance3D.new()
	smear_mesh.mesh = mesh.mesh
	smear_mesh.add_to_group(SMEAR_GROUP)
	smear_mesh.layers = mesh.layers
	mesh.add_child(smear_mesh)  # add to tree FIRST

	var smear_material := ShaderMaterial.new()
	smear_material.shader = smear_shader
	if noise_texture:
		smear_material.set_shader_parameter("noise", noise_texture)
	smear_material.set_shader_parameter("albedo_color", initial_color)
	smear_material.set_shader_parameter("lag_transform", holder.global_transform)
	smear_material.set_shader_parameter("current_transform", holder.global_transform)
	smear_mesh.set_surface_override_material(0, smear_material)
	smear_materials.append(smear_material)
	smear_meshes.append(smear_mesh)

	# Now add outline mesh as child of smear_mesh (which is already in tree)
	var outline_mesh := MeshInstance3D.new()
	outline_mesh.mesh = mesh.mesh
	outline_mesh.add_to_group(SMEAR_GROUP)
	outline_mesh.layers = mesh.layers
	outline_mesh.visible = false
	# DON'T assign material here - let set_outline handle it
	smear_mesh.add_child(outline_mesh)
	outline_meshes.append(outline_mesh)


#region COLORS

func reset_colors() -> void:

	for i in mesh_materials.size():

		var mat = mesh_materials[i]

		if mat:
			mat.albedo_color = default_colors[i]


func set_color(color: Color) -> void:

	for mat in mesh_materials:

		if mat:
			mat.albedo_color = color


func lerp_color(
	color: Color,
	weight: float
) -> void:

	for i in mesh_materials.size():

		var mat = mesh_materials[i]

		if mat:

			mat.albedo_color = default_colors[i].lerp(
				color,
				weight
			)


#endregion


#region alpha

func set_alpha(alpha: float) -> void:

	alpha = clampf(alpha, 0.0, 1.0)

	for i in mesh_materials.size():

		var mat = mesh_materials[i]

		if mat:

			var color = mat.albedo_color
			color.a = alpha

			mat.albedo_color = color

			# Required for transparency
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA


func reset_alpha() -> void:

	for i in mesh_materials.size():

		var mat = mesh_materials[i]

		if mat:

			var color = mat.albedo_color
			color.a = default_colors[i].a

			mat.albedo_color = color

			if color.a >= 1.0:
				mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED


func lerp_alpha(
	target_alpha: float,
	weight: float
) -> void:

	target_alpha = clampf(target_alpha, 0.0, 1.0)

	for i in mesh_materials.size():

		var mat = mesh_materials[i]

		if mat:

			var color = mat.albedo_color

			color.a = lerpf(
				default_colors[i].a,
				target_alpha,
				weight
			)

			mat.albedo_color = color

			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA


#endregion

#region FLASH

func flash() -> void:

	var tween = create_tween()

	tween.tween_method(
		set_flash,
		0.0,
		1.0,
		0.08
	)

	tween.tween_method(
		set_flash,
		1.0,
		0.0,
		0.12
	)\
	.set_trans(Tween.TRANS_QUAD)\
	.set_ease(Tween.EASE_OUT)


func set_flash(value: float) -> void:
	for mat in mesh_materials:
		if mat:
			mat.emission = Color.WHITE
			mat.emission_energy = value * 5.0

	for mat in smear_materials:  # <-- this must be here
		if mat:
			mat.set_shader_parameter("emission_color", Vector4(1, 1, 1, 1))
			mat.set_shader_parameter("emission_energy", value * 5.0)

func clear_flash() -> void:
	for mat in mesh_materials:
		if mat:
			mat.emission_energy = 0.0

	for mat in smear_materials:  # <-- and here
		if mat:
			mat.set_shader_parameter("emission_energy", 0.0)


func flash_color(
	color: Color,
	intensity := 5.0
) -> void:

	for mat in mesh_materials:

		if mat:

			mat.emission = color
			mat.emission_energy = intensity



#endregion


#region OUTLINES

func set_outline(val: bool) -> void:
	if !_outline_material:
		push_error("MaterialManagerComponent: _outline_material is null in set_outline")
		return

	_outline_material.set_shader_parameter("outline_width", outline_width)

	for mat in mesh_materials:
		if mat:
			mat.next_pass = _outline_material if val else null

	for omesh in outline_meshes:
		if omesh:
			omesh.visible = val
			if val:
				omesh.set_surface_override_material(0, _outline_material)
			else:
				omesh.set_surface_override_material(0, null)
#endregion
