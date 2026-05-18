extends CanvasLayer

@onready var control: Control = $Control
@onready var telekinesis_indicator = %TelekinesisIndicator;
@onready var timer: Label = %Timer;
@onready var score: Label = %Score
@onready var rockets_container: HBoxContainer = %RocketsContainer
@onready var health: Label = %Health
@onready var telekinesis_container: HBoxContainer = %TelekinesisContainer
@onready var crossair: TextureRect = $Control/Crossair

@export var hud_drag_elements: Array[Node2D] = []
@export var hud_rotation_drag: float = 5.0
@export var hud_max_drag_x: float = 20.0
@export var hud_max_drag_y: float = 12.0
@export var hud_weight_min: float = 0.6
@export var hud_weight_max: float = 1.2
var random = RandomNumberGenerator.new();

var _hud_prev_basis: Basis
var _hud_base_positions: Dictionary = {}
var _hud_weights: Dictionary = {}

@onready var health_icon: TextureRect = %HealthIcon
@export var health_fill_color: Color = Color(0.2, 0.85, 0.3, 1.0)  # customize in Inspector
var health_shader_material: ShaderMaterial = preload("uid://du687qgg4mtql")
@onready var health_outline: AnimatedSprite2D = %HealthOutline

@export var background_bar_color : Color = Color()
@export var background_fill_color : Color = Color()
const PROGRESS_BAR_OUTLINE = preload("uid://cngbqdu7mvtal")

var viewport_scale := 1.0;

var telekinesis_bar : ProgressBar;

var rockets := []
var dashes := []

var telekinesis_target : CharacterBody3D;

var telekinesis_bar_width := 64 * 4 + 8 * 3;

var bar_bg = StyleBoxFlat.new()
var bar_fill = StyleBoxFlat.new()

const PROGRESS_BAR_STYLE_BOX = preload("uid://bwtyb1pq6q8nx")

var lerp_delta_multiplier = 6;

func _ready() -> void:
	LevelController.gameplay_HUD = self;
	
	crossair.set_anchors_preset(Control.PRESET_CENTER)
	crossair.set_offsets_preset(Control.PRESET_CENTER)
	
	#get_rockets();

	await get_tree().physics_frame
	
	get_dashes();
	get_telekinesis()
	
	health_shader_material.set_shader_parameter("fill_color", health_fill_color)
	health_shader_material.set_shader_parameter("health_percent", 1.0)
	health_icon.material = health_shader_material
	
	health_outline.play("default")
	
	var cam = LevelController.player_camera
	_hud_prev_basis = cam.global_basis

	await get_tree().process_frame
	for node in hud_drag_elements:
		if node:
			_hud_base_positions[node] = node.position
			_hud_weights[node] = random.randf_range(hud_weight_min, hud_weight_max)

func make_bg_stylebox() -> StyleBoxTexture:
	var sb = PROGRESS_BAR_STYLE_BOX.duplicate()
	sb.modulate_color = background_bar_color
	return sb

func make_fill_stylebox() -> StyleBoxTexture:
	var sb = PROGRESS_BAR_STYLE_BOX.duplicate()
	sb.modulate_color = background_fill_color
	return sb

func make_progress_bar(width: float, height: float) -> Dictionary:
	var container = Control.new()
	container.custom_minimum_size = Vector2(width, height)
	
	var bar = ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 1
	bar.value = 0
	bar.custom_minimum_size = Vector2(width, height)
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", make_bg_stylebox())
	bar.add_theme_stylebox_override("fill", make_fill_stylebox())

	
	var outline : NinePatchRect = PROGRESS_BAR_OUTLINE.instantiate()
	outline.scale = Vector2.ONE
	outline.position = Vector2.ZERO - Vector2(4, 6)

	container.add_child(bar)
	container.add_child(outline)
	outline.size = Vector2(width + 12, height + 10)
	
	return { "container": container, "bar": bar, "outline": outline }

func get_telekinesis() -> void:
	var result = make_progress_bar(telekinesis_bar_width, 24)
	telekinesis_bar = result.bar
	telekinesis_container.add_child(result.container)

func get_dashes() -> void:
	rockets_container.set_anchors_preset(Control.PRESET_TOP_LEFT)
	rockets_container.add_theme_constant_override("separation", 8)
	
	for i in range(LevelController.player.dash_component.dash_max_count):
		var result = make_progress_bar(telekinesis_bar_width / 2 - 4, 24)
		rockets_container.add_child(result.container)
		dashes.append(result.bar)

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

func set_dashes(val : float) -> void:
	for i in range(dashes.size()):
		var v = clampf(val - i, 0.0, 1.0)
		dashes[i].value = v

var visual_health := 100.;
var target_health := 100.;
func set_health(val: float, delta : float) -> void:
	
	target_health = val;
	if target_health >= visual_health : visual_health = target_health;
	
	visual_health = lerpf(visual_health, target_health, 6 * delta)


	var txt = "%.0f" % visual_health
	health.text = txt
	
	# Update shader — assuming max health is 100, adjust if different
	var max_health = LevelController.player.health_component.get_max()
	var pct = clampf(visual_health / max_health, 0.0, 1.0)
	health_shader_material.set_shader_parameter("health_percent", pct)


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


	var dist = cam.global_position.distance_to(center.global_position)
	var scale_factor = 1.0
	if dist > 4:
		scale_factor = clampf(4.0 / dist, 0.05, 1.0)

	telekinesis_indicator.visible = true
	telekinesis_indicator.position = screen_pos - telekinesis_indicator.scale / 2
	telekinesis_indicator.scale = Vector2.ONE * scale_factor

func set_timer(time: String):
	timer.text = time


var score_visual := 0.;
func set_score(val : float, delta : float):
	
	score_visual = lerp(score_visual, val, delta * lerp_delta_multiplier);
	score_visual = ceil(score_visual);
	if val <= score_visual : score_visual = val;
	
	score.text = score_to_str(score_visual);

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

		var world_pos : Vector3
		if enemy.has_method("get_center_point"):
			var center = enemy.get_center_point()
			world_pos = center.global_position if center != null else enemy.global_position
		else:
			world_pos = enemy.global_position

		# Scale based on distance
		var dist = cam.global_position.distance_to(world_pos)
		var scale_factor = 1.0
		if dist > 4:
			scale_factor = clampf(4.0 / dist, 0.05, 1.0)
		indicator.scale = Vector2.ONE * scale_factor

		var indicator_size = indicator.texture.get_size() * indicator.scale
		var half = indicator_size / 2.0

		# Check if behind camera
		var to_target = world_pos - cam.global_position
		var is_behind = to_target.dot(-cam.global_transform.basis.z) < 0

		var screen_pos: Vector2
		if is_behind:
			# Project anyway but flip so it points to the correct edge
			screen_pos = cam.unproject_position(world_pos) * viewport_scale
			screen_pos *= window_size / viewport_size
			screen_pos = Vector2(window_size.x / 2, window_size.y / 2) + \
				(Vector2(window_size.x / 2, window_size.y / 2) - screen_pos).normalized() * 9999.0
		else:
			screen_pos = cam.unproject_position(world_pos) * viewport_scale
			screen_pos *= window_size / viewport_size

		# Clamp to screen edge
		screen_pos.x = clampf(screen_pos.x, WARNING_MARGIN + half.x, window_size.x - WARNING_MARGIN - half.x)
		screen_pos.y = clampf(screen_pos.y, WARNING_MARGIN + half.y, window_size.y - WARNING_MARGIN - half.y)

		indicator.visible = true
		indicator.position = screen_pos

func score_to_str(score: float) -> String:
	
	return "%08d" % score;

func _update_hud_drag(delta: float) -> void:
	var cam = LevelController.player_camera
	var cur_basis: Basis = cam.global_basis
	var rot_delta: Basis = _hud_prev_basis.inverse() * cur_basis
	var euler: Vector3 = rot_delta.get_euler()

	var yaw: float = euler.y
	var pitch: float = euler.x

	for node in _hud_base_positions.keys():
		var base: Vector2 = _hud_base_positions[node]
		var w: float = _hud_weights[node]

		var target_x: float = base.x + clamp(yaw * hud_max_drag_x * 100.0 * w, -hud_max_drag_x * w, hud_max_drag_x * w)
		var target_y: float = base.y + clamp(pitch * hud_max_drag_y * 100.0 * w, -hud_max_drag_y * w, hud_max_drag_y * w)

		node.position.x = lerp(node.position.x, target_x, hud_rotation_drag * delta)
		node.position.y = lerp(node.position.y, target_y, hud_rotation_drag * delta)

		node.position.x = lerp(node.position.x, base.x, hud_rotation_drag * delta * 0.5)
		node.position.y = lerp(node.position.y, base.y, hud_rotation_drag * delta * 0.5)

	_hud_prev_basis = cur_basis

func _process(delta : float):
	
	_update_hud_drag(delta)
	
	set_telekinesis(LevelController.player.telekinesis_component.get_cooldown_progress())
	set_health(LevelController.player.health_component.get_health(), delta)
	set_dashes(LevelController.player.dash_component.get_dash())
	#set_rocket_bars(LevelController.player.rocket_launcher_component.get_rockets())
	
	
	set_timer(LevelController.time_to_str())
	set_score(LevelController.get_score(), delta)
	set_telekinesis_indicator();
	update_blaster_warnings()
