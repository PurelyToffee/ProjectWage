extends CanvasLayer

@onready var telekinesis_indicator: Sprite2D = %TelekinesisIndicator
var telekinesis_target: CharacterBody3D

func _ready() -> void:
	LevelController.gameplay_HUD_middle = self

func set_telekinesis_target(enemy: CharacterBody3D) -> void:
	telekinesis_target = enemy

func get_telekinesis_target() -> CharacterBody3D:
	return telekinesis_target

func set_telekinesis_indicator() -> void:
	if telekinesis_target == null:
		telekinesis_indicator.visible = false
		return

	var cam = LevelController.player_camera
	var world_pos = telekinesis_target.global_position + Vector3(0, 1.0, 0)

	var to_target = world_pos - cam.global_position
	if to_target.dot(-cam.global_transform.basis.z) < 0:
		telekinesis_indicator.visible = false
		return

	var screen_pos := cam.unproject_position(world_pos)
	var viewport_size := Vector2(cam.get_viewport().size)
	var container_size := get_viewport().get_visible_rect().size
	var scale_ratio := container_size / viewport_size
	var adjusted := screen_pos * scale_ratio

	var dist = cam.global_position.distance_to(world_pos)
	var scale_factor := 1.0
	if dist > 4.0:
		scale_factor = clampf(4.0 / dist, 0.05, 1.0)

	telekinesis_indicator.visible = true
	telekinesis_indicator.scale = Vector2.ONE * scale_factor
	telekinesis_indicator.position = adjusted

func _process(_delta: float) -> void:
	set_telekinesis_indicator()
