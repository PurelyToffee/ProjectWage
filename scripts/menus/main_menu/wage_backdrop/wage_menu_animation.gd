extends AnimationPlayerParent

@export var tail_player: AnimationPlayer  # second AnimationPlayer node, assign in inspector

@export var breathing_gap: float = 2.0
@export var tail_min_delay: float = 3.0
@export var tail_max_delay: float = 8.0

var _breathing_timer: Timer
var _tail_timer: Timer


func _ready() -> void:
	super._ready()

	animation_finished.connect(_on_animation_finished)

	_breathing_timer = Timer.new()
	_breathing_timer.one_shot = true
	_breathing_timer.timeout.connect(_play_breathing)
	add_child(_breathing_timer)

	_tail_timer = Timer.new()
	_tail_timer.one_shot = true
	_tail_timer.timeout.connect(_play_tail)
	add_child(_tail_timer)

	if tail_player:
		tail_player.animation_finished.connect(_on_tail_finished)

	play("Start")
	_queue_next_tail()


func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Start":
		_play_breathing()
	elif anim_name == "BreathingLoop":
		_breathing_timer.start(breathing_gap)


func _on_tail_finished(anim_name: StringName) -> void:
	if anim_name == "TailLoop":
		_queue_next_tail()


func _play_breathing() -> void:
	play("BreathingLoop")


func _play_tail() -> void:
	if tail_player:
		tail_player.play("TailLoop")


func _queue_next_tail() -> void:
	_tail_timer.start(randf_range(tail_min_delay, tail_max_delay))
