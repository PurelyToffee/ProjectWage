extends Label3D

@onready var fade_out: Timer = %FadeOut
@onready var hit_flash: Timer = %HitFlash

var flavour_text := ["Bam!", "Hit!", "Pow!", "Nice!"]
var color : Color;
var spd := 3.;

var rng = RandomNumberGenerator.new();
func _ready() -> void:
	
	fade_out.start(rng.randf_range(1., 2.))

func init(damage: int, is_headshot: bool) -> void:
	
	#var range := 0.4;
	#global_position += Vector3(rng.randf_range(-range, range), rng.randf_range(-range, range), rng.randf_range(-range, range));
	
	text = flavour_text.pick_random()
	color = Color("ffb812ff") if is_headshot else Color("C5312Fff")

func change_color() -> void:
	self.modulate = color;

func fade_and_free() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	await tween.finished
	queue_free()

func _process(delta: float) -> void:
	position.y += delta * spd
	spd = clampf(spd - 0.01, 2., 3.);
	
