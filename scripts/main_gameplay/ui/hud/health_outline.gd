extends AnimatedSprite2D

@export var animated_frames : Array[SpriteFrames];

func _ready() -> void:
	play("default")

func set_sprite(index : int) -> void:
	sprite_frames = animated_frames[index]
	play("default")
