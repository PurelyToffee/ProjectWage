class_name ConfirmationPopup
extends Control

@onready var description: Label = %Description
@onready var confirmation_button: PanelContainer = %ConfirmationButton
@onready var cancel_button: PanelContainer = %CancelButton

const FADE_DURATION := 0.25

func _ready() -> void:
	fade_in()
	set_cancel(fade_out)

func fade_in() -> void:
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, FADE_DURATION)

func fade_out() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, FADE_DURATION)
	tween.finished.connect(queue_free)

func set_confirmation(call: Callable) -> void:
	confirmation_button.pressed.connect(func() : 
		call.call()
		fade_out();
	)

func set_cancel(call: Callable) -> void:
	cancel_button.pressed.connect(func() : 
		call.call()
		fade_out();
	)

func set_description(text: String) -> void:
	description.text = text
