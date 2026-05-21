class_name WeaponSlot extends GameplayHudElement

@onready var progress_bar_outline: NinePatchRect = %ProgressBarOutline
@onready var sub_viewport_container: SubViewportContainer = $SubViewportContainer
@onready var animated_sprite_2d: AnimatedSprite2D = $SubViewportContainer/SubViewport/AnimatedSprite2D

func _ready() -> void:
	animated_sprite_2d.play("default")

func set_alpha(val : float) -> void:
	sub_viewport_container.modulate.a = val;
