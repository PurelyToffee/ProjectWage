extends CanvasLayer

enum states {
	READY,
	SET,
	RUN,
}

var slow: bool = true

@onready var label: Label = %Label
var state = states.READY
var timer: Timer = Timer.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	label.text = "Ready..."
	self.add_child(timer)
	timer.start(1.0)
	timer.timeout.connect(_on_timeout)

func _on_timeout() -> void:
	if state == states.RUN:
		self.queue_free()
		return
	state = (state+1) as states;
	if !slow and state == states.SET:
		state = states.RUN
	
	match state:
		states.SET:
			label.text = "Set..."
		states.RUN:
			LevelController.close_menu()
			label.text = "RUN!"
			label.add_theme_font_size_override("font_size", 200)
	timer.start(1.0)
