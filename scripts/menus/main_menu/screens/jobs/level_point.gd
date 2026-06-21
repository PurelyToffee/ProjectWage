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

func _ready() -> void:
	popup.hide()
	_refresh()
	button.pressed.connect(_on_pressed)
	button.mouse_entered.connect(func(): popup.show())
	button.mouse_exited.connect(func(): popup.hide())

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
	
	GameController.confirm_popup("Do you want to load %s?" % level_name, func():
		GameController.load_level(level_id)
		dialog.queue_free())
