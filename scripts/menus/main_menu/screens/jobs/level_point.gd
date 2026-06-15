# level_point.gd
extends Control

@export var level_id : int
@export var level_name : String
@export var level_preview : Texture2D

@onready var grade: Label = %Grade
@onready var time: Label = %Time
@onready var name_label: Label = %Name
@onready var popup: Control = %Popup
@onready var preview_image: TextureRect = %PreviewImage

@onready var button: Button = %Button
@onready var color_rect: ColorRect = %ColorRect
@onready var margin_container: MarginContainer = %MarginContainer
@onready var panel_container: PanelContainer = %PanelContainer

var loading_screen: Control
var load_progress: Array = []

func _ready() -> void:
	popup.hide()
	_refresh()
	button.pressed.connect(_on_pressed)
	button.mouse_entered.connect(func(): popup.show())
	button.mouse_exited.connect(func(): popup.hide())
	var jobs_screen = find_parent("JobsScreen")
	loading_screen = jobs_screen.find_child("LoadingScreen")
	set_process(false)

func _refresh() -> void:
	name_label.text = level_name
	preview_image.texture = level_preview
	
	var scores = GameData.data["level_scores"]
	if scores.has(level_id):
		var s = scores[level_id]
		grade.text = s["grade"]
		time.text = LevelController.time_to_str(s["time"])
	else:
		grade.text = "#"
		time.text = "--:--:---"
	
	panel_container.reset_size()
	var old_size = color_rect.size.x;
	color_rect.size.x = panel_container.size.x
	popup.position.x += (old_size - color_rect.size.x)/2
		

func _on_pressed() -> void:
	
	if !GameController.in_main_menu():
		return;
	
	var dialog = ConfirmationDialog.new()
	dialog.title = "Load Level"
	dialog.dialog_text = "Load %s?" % level_name
	
	
	get_tree().root.add_child(dialog)
	dialog.popup_centered()
	
	dialog.confirmed.connect(func():
		loading_screen.modulate.a = 0.0
		loading_screen.visible = true
		#GameController.load_level(level_id)
		ResourceLoader.load_threaded_request(GameController.levels[level_id].scene_path, "", true)
		dialog.queue_free()
		set_process(true)
	)
	dialog.canceled.connect(func():
		dialog.queue_free()
	)

func _process(delta: float) -> void:
	var level_path = GameController.levels[level_id].scene_path
	loading_screen.modulate.a = minf(1.0, loading_screen.modulate.a + delta)
	var status = ResourceLoader.load_threaded_get_status(level_path, load_progress)
	if status == ResourceLoader.THREAD_LOAD_LOADED && loading_screen.modulate.a == 1.0:
		var scene = ResourceLoader.load_threaded_get(level_path)
		GameController.load_level(level_id, scene)
		loading_screen.visible = false
		set_process(false)
