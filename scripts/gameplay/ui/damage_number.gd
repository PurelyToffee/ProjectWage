extends Label3D

@onready var fade_out: Timer = %FadeOut
@onready var hit_flash: Timer = %HitFlash

enum HitType { NORMAL, HEADSHOT, KICK }

@export_group("Flavour Text")
## Words shown for normal hits and headshots.
@export var flavour_text : Array[String] = ["Bam!", "Hit!", "Pow!", "Nice!"]
## Words shown for kicks (its own punchier set).
@export var kick_flavour : Array[String] = ["KICK!", "SMASH!", "WHAM!", "BOOM!"]

@export_group("Font Size")
@export var normal_font_size : int = 64
## Headshots read bigger than normal shots.
@export var headshot_font_size : int = 88
## Kicks are the biggest.
@export var kick_font_size : int = 120

@export_group("Color")
@export var normal_color : Color = Color("C5312Fff")
@export var headshot_color : Color = Color("ffb812ff")
@export var kick_color : Color = Color("ff7b1aff")

var color : Color;
var spd := 3.;

var rng = RandomNumberGenerator.new();
func _ready() -> void:

	fade_out.start(rng.randf_range(1., 2.))

func init(damage: int, is_headshot: bool, is_kick: bool = false) -> void:

	#var range := 0.4;
	#global_position += Vector3(rng.randf_range(-range, range), rng.randf_range(-range, range), rng.randf_range(-range, range));

	var type := HitType.KICK if is_kick else (HitType.HEADSHOT if is_headshot else HitType.NORMAL)

	match type:
		HitType.KICK:
			text = _pick(kick_flavour)
			color = kick_color
			font_size = kick_font_size
		HitType.HEADSHOT:
			text = _pick(flavour_text)
			color = headshot_color
			font_size = headshot_font_size
		_:
			text = _pick(flavour_text)
			color = normal_color
			font_size = normal_font_size

func _pick(list : Array[String]) -> String:
	return list.pick_random() if list.size() > 0 else ""

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
	
