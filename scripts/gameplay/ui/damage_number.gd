extends Label3D

@onready var timer: Timer = %Timer

var flavour_text := ["Bam!", "Hit!", "Pow!", "Nice!"]

var rng = RandomNumberGenerator.new();
func _ready() -> void:
	timer.wait_time = rng.randf_range(0.8, 2.)

func init(damage: int, is_headshot: bool) -> void:
	text = flavour_text.pick_random()
	modulate = Color("EF9849ff") if is_headshot else Color("9D312Fff")

func fade_and_free() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	await tween.finished
	queue_free()

func _process(delta: float) -> void:
	position.y += delta * 2
