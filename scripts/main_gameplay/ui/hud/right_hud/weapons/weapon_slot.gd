class_name WeaponSlot extends GameplayHudElement

@onready var progress_bar_outline: NinePatchRect = %ProgressBarOutline
@onready var sub_viewport_container: SubViewportContainer = $SubViewportContainer
@onready var canvas_group: CanvasGroup = %CanvasGroup
@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D

# Tracks the shader fade value
var shader_alpha: float = 1.

func _ready() -> void:
	
	#animated_sprite_2d.play("default")
	
	canvas_group.material = canvas_group.material.duplicate()
	# Initialize shader parameter
	canvas_group.material.set_shader_parameter("alpha", shader_alpha)

func set_alpha(val: float) -> void:
	shader_alpha = clampf(val, 0.0, 1.0)

	if canvas_group and canvas_group.material:
		canvas_group.material.set_shader_parameter("alpha", shader_alpha)
