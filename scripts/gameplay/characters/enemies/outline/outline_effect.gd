@tool
extends CompositorEffect
class_name OutlineEffect

@export var outline_color: Color = Color(0xffb812ff)
@export var thickness: float = 3.0

var rd: RenderingDevice
var shader: RID
var pipeline: RID
var parameter_buffer: RID
var depth_sampler: RID

func _init() -> void:
	effect_callback_type = CompositorEffect.EFFECT_CALLBACK_TYPE_POST_TRANSPARENT
	rd = RenderingServer.get_rendering_device()

	var shader_file: RDShaderFile = load("uid://ctv0xxj3d1pih")
	var shader_spirv := shader_file.get_spirv()
	shader = rd.shader_create_from_spirv(shader_spirv)
	pipeline = rd.compute_pipeline_create(shader)

	var data := PackedFloat32Array()
	data.resize(12)
	data.fill(0.0)
	parameter_buffer = rd.storage_buffer_create(data.to_byte_array().size(), data.to_byte_array())

	var sampler_state := RDSamplerState.new()
	sampler_state.min_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
	sampler_state.mag_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
	depth_sampler = rd.sampler_create(sampler_state)

func _render_callback(_callback_type: int, render_data: RenderData) -> void:
	if rd == null or not shader.is_valid() or not pipeline.is_valid():
		return

	var render_scene_buffers: RenderSceneBuffersRD = render_data.get_render_scene_buffers()
	if not render_scene_buffers:
		return

	var size := render_scene_buffers.get_internal_size()
	if size.x == 0 or size.y == 0:
		return

	var enemy_depth_rid : RID = OutlineManager.enemy_depth_rid
	if not enemy_depth_rid.is_valid():
		push_warning("OutlineEffect: enemy depth RID not yet available.")
		return

	var enemy_depth_sampler: RID = OutlineManager.enemy_depth_sampler
	if not enemy_depth_sampler.is_valid():
		push_warning("OutlineEffect: enemy depth sampler not yet available.")
		return

	var linear_color = outline_color.srgb_to_linear()
	var params := PackedFloat32Array([
		float(size.x), float(size.y),
		0.0, 0.0,
		linear_color.r, linear_color.g, linear_color.b, linear_color.a,
		thickness,
		0.0, 0.0, 0.0
	])
	rd.buffer_update(parameter_buffer, 0, params.to_byte_array().size(), params.to_byte_array())

	var param_uniform := RDUniform.new()
	param_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	param_uniform.binding = 0
	param_uniform.add_id(parameter_buffer)

	var color_uniform := RDUniform.new()
	color_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	color_uniform.binding = 1
	color_uniform.add_id(render_scene_buffers.get_color_layer(0))

	var depth_uniform := RDUniform.new()
	depth_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	depth_uniform.binding = 2
	depth_uniform.add_id(depth_sampler)
	depth_uniform.add_id(render_scene_buffers.get_depth_layer(0))

	var enemy_depth_uniform := RDUniform.new()
	enemy_depth_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	enemy_depth_uniform.binding = 3
	enemy_depth_uniform.add_id(enemy_depth_sampler)
	enemy_depth_uniform.add_id(enemy_depth_rid)

	var bindings: Array[RDUniform] = [
		param_uniform,
		color_uniform,
		depth_uniform,
		enemy_depth_uniform,
	]

	var groups := Vector3i(
		int(ceil(float(size.x) / 8.0)),
		int(ceil(float(size.y) / 8.0)),
		1
	)

	var uniform_set := rd.uniform_set_create(bindings, shader, 0)
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_dispatch(compute_list, groups.x, groups.y, groups.z)
	rd.compute_list_end()

	rd.free_rid(uniform_set)
