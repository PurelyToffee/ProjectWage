@tool
extends CompositorEffect
class_name EnemyDepthCapture

var sampler_created := false

func _init() -> void:
	effect_callback_type = CompositorEffect.EFFECT_CALLBACK_TYPE_POST_TRANSPARENT

func _render_callback(_callback_type: int, render_data: RenderData) -> void:
	if not sampler_created:
		var rd := RenderingServer.get_rendering_device()
		var sampler_state := RDSamplerState.new()
		sampler_state.min_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
		sampler_state.mag_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
		OutlineManager.enemy_depth_sampler = rd.sampler_create(sampler_state)
		sampler_created = true

	var scene_buffers := render_data.get_render_scene_buffers() as RenderSceneBuffersRD
	if not scene_buffers:
		return
	var depth_rid := scene_buffers.get_depth_layer(0)
	if depth_rid.is_valid():
		OutlineManager.enemy_depth_rid = depth_rid
