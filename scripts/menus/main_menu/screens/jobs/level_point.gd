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
		grade.text = "-"
		time.text = "--:--:---"

func _on_pressed() -> void:
	pass # hook this up to your level loading later
