extends CanvasLayer

@onready var telekinesis_indicator = %TelekinesisIndicator;
@onready var cross_air: Sprite2D = %CrossAir
@onready var timer: Label = %Timer;
@onready var score: Label = %Score


var telekinesis_target : CharacterBody3D;

func _ready() -> void:
	LevelController.gameplay_HUD = self;
	
	cross_air.position = get_viewport().get_visible_rect().size / 2


func set_telekinesis_target(enemy : CharacterBody3D) -> void:
	telekinesis_target = enemy
	
func get_telekinesis_target() -> CharacterBody3D:
	return telekinesis_target;
	

func set_telekinesis_indicator() -> void:
	if telekinesis_target == null:
		telekinesis_indicator.visible = false
		return

	var cam = LevelController.player_camera
	var center = telekinesis_target.get_center_point()
	if center == null : return;
	
	var to_target = center.global_position - cam.global_position
	var is_behind = to_target.dot(-cam.global_transform.basis.z) < 0

	if is_behind:
		telekinesis_indicator.visible = false
		return

	var screen_pos = cam.unproject_position(center.global_position)

	var dist = cam.global_position.distance_to(center.global_position)
	var scale_factor = 1.0
	if dist > 4:
		scale_factor = clampf(4.0 / dist, 0.05, 1.0)

	telekinesis_indicator.visible = true
	telekinesis_indicator.position = screen_pos - telekinesis_indicator.scale / 2
	telekinesis_indicator.scale = Vector2.ONE * scale_factor

func set_timer(time: String):
	timer.text = time
	
func set_score(val : String):
	score.text = val;

func _process(delta):
	set_timer(LevelController.time_to_str())
	set_score(LevelController.score_to_str())
	set_telekinesis_indicator();
