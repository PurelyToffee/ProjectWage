extends CanvasLayer

@onready var control: Control = $Control
@onready var telekinesis_indicator = %TelekinesisIndicator;
@onready var timer: Label = %Timer;
@onready var score: Label = %Score
@onready var rockets_container: HBoxContainer = %RocketsContainer
@onready var health: Label = %Health
@onready var telekinesis_container: HBoxContainer = %TelekinesisContainer
@onready var crossair: TextureRect = $Control/Crossair

var viewport_scale := 1.0;

var telekinesis_bar : ProgressBar;

var rockets := []

var telekinesis_target : CharacterBody3D;

func _ready() -> void:
	LevelController.gameplay_HUD = self;
	
	crossair.set_anchors_preset(Control.PRESET_CENTER)
	crossair.set_offsets_preset(Control.PRESET_CENTER)
	
	#get_rockets();
		
	telekinesis_bar = ProgressBar.new()
	telekinesis_bar.min_value = 0
	telekinesis_bar.max_value = 1
	telekinesis_bar.value = 0
	telekinesis_bar.custom_minimum_size = Vector2(64 * 4 + 8 * 3, 16)
	telekinesis_bar.show_percentage = false
	telekinesis_container.add_child(telekinesis_bar)

func get_rockets() -> void:
	rockets_container.set_anchors_preset(Control.PRESET_TOP_LEFT)
	rockets_container.add_theme_constant_override("separation", 8)
	
	
	for i in range(4):
		var rocket = ProgressBar.new()
		rocket.min_value = 0
		rocket.max_value = 1
		rocket.value = 0
		rocket.custom_minimum_size = Vector2(64, 16)
		rocket.show_percentage = false
		
		rockets_container.add_child(rocket)
		rockets.append(rocket)

func set_telekinesis(val : float) -> void:
	telekinesis_bar.value = val;

func set_health(val : float) -> void:
	
	var txt = "%.0f" % val;
	
	health.text = txt;

func set_rocket_bars(amount: float) -> void:
	
	for i in range(rockets.size()):
		var v = clampf(amount - i, 0.0, 1.0)
		rockets[i].value = v

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

	var screen_pos = cam.unproject_position(center.global_position) * viewport_scale;

	var viewport_size = Vector2(get_viewport().size)
	var window_size = get_viewport().get_visible_rect().size

	screen_pos *= window_size / viewport_size

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

@export var blaster_warning_scene : PackedScene
@export var blaster_warning_critical_texture : Texture2D;

var blaster_warnings : Dictionary = {} 
const WARNING_MARGIN := 32.0 

func add_blaster_warning(enemy: Node) -> void:
	if enemy in blaster_warnings:
		return
		
		
	var indicator = blaster_warning_scene.instantiate()
	control.add_child(indicator)
	
	blaster_warnings[enemy] = indicator

func set_blaster_warning_critical(enemy : Node) -> void:
	if enemy not in blaster_warnings:
		return;
		
	blaster_warnings[enemy].texture = blaster_warning_critical_texture;

func remove_blaster_warning(enemy: Node) -> void:
	if enemy not in blaster_warnings:
		return
	blaster_warnings[enemy].queue_free()
	blaster_warnings.erase(enemy)

func update_blaster_warnings() -> void:
	var cam = LevelController.player_camera
	var window_size = get_viewport().get_visible_rect().size
	var viewport_size = Vector2(get_viewport().size)
	
	for enemy in blaster_warnings.keys():
		var indicator : Sprite2D = blaster_warnings[enemy]
		
		# Clean up if enemy was freed
		if !is_instance_valid(enemy):
			indicator.queue_free()
			blaster_warnings.erase(enemy)
			continue

		# Use the enemy's center point or global_position as fallback
		var world_pos : Vector3
		if enemy.has_method("get_center_point"):
			var center = enemy.get_center_point()
			world_pos = center.global_position if center != null else enemy.global_position
		else:
			world_pos = enemy.global_position

		# Check if behind camera
		var to_target = world_pos - cam.global_position
		var is_behind = to_target.dot(-cam.global_transform.basis.z) < 0
		if is_behind:
			indicator.visible = false
			continue

		# Project to screen
		var screen_pos = cam.unproject_position(world_pos) * viewport_scale
		screen_pos *= window_size / viewport_size

		var indicator_size = indicator.texture.get_size();

		# Clamp to screen with margin so it never goes off-screen
		var half = indicator_size * indicator.scale / 2.0
		screen_pos.x = clampf(screen_pos.x, WARNING_MARGIN + half.x, window_size.x - WARNING_MARGIN - half.x)
		screen_pos.y = clampf(screen_pos.y, WARNING_MARGIN + half.y, window_size.y - WARNING_MARGIN - half.y)

		indicator.visible = true
		indicator.position = screen_pos

func _process(delta):
	
	
	set_telekinesis(LevelController.player.telekinesis_component.get_cooldown_progress())
	set_health(LevelController.player.health_component.get_health())
	#set_rocket_bars(LevelController.player.rocket_launcher_component.get_rockets())
	
	set_timer(LevelController.time_to_str())
	set_score(LevelController.score_to_str())
	set_telekinesis_indicator();
	update_blaster_warnings()
