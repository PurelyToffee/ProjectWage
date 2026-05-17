extends NinePatchRect

var frames := [
	preload("uid://nwtsxbd6l3ho"),
	preload("uid://p8escfky8nir"),
	preload("uid://bgm13p12lnv0d")
]


var frame_index := randi_range(0, 2)
var frame_timer := 0.0
@export var FPS := 5.0

func _process(delta):
	frame_timer += delta
	while frame_timer >= 1.0 / FPS:
		frame_timer -= 1.0 / FPS
		frame_index = (frame_index + 1) % frames.size()
		self.texture = frames[frame_index]
