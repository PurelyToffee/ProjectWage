class_name MenuOption extends Control

signal pressed

@onready var button: Button = $Button
@onready var texture_rect: TextureRect = %TextureRect

@export var normal_texture: Texture2D
@export var hover_texture: Texture2D

func _ready() -> void:
	button.pressed.connect(func(): pressed.emit())
	button.mouse_entered.connect(func(): texture_rect.texture = hover_texture)
	button.mouse_exited.connect(func(): texture_rect.texture = normal_texture)
