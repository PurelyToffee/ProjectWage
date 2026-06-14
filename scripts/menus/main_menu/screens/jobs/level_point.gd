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

var is_loading_level: bool = false
var loading_screen: Control

func _ready() -> void:
	popup.hide()
	_refresh()
	button.pressed.connect(_on_pressed)
	button.mouse_entered.connect(func(): popup.show())
	button.mouse_exited.connect(func(): popup.hide())
	var jobs_screen = find_parent("JobsScreen")
	loading_screen = jobs_screen.find_child("LoadingScreen")

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
		is_loading_level = true
		loading_screen.modulate.a = 0.0
		loading_screen.visible = true
		GameController.load_level(level_id)
		dialog.queue_free()
		is_loading_level = false
	)
	dialog.canceled.connect(func():
		dialog.queue_free()
	)

func _process(delta: float) -> void:
	if is_loading_level:
		#TODO: this is unreachable
		print("meow")
		loading_screen.modulate.a = 0.5
