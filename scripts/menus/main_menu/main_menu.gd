extends Control

enum States { SPLASHSCREEN, MENU }
var state: States = States.SPLASHSCREEN

@onready var bottom_bar: HBoxContainer = %BottomBar
@onready var splash_layer: Control = %SplashLayer
@onready var options: Control = %Options
@onready var margin_container: MarginContainer = %MarginContainer

@onready var jobs_option: Control = %JobsOption
@onready var settings_option: Control = %SettingsOption
@onready var extras_option: Control = %ExtrasOption


func _ready() -> void:
	options.position.y = get_viewport_rect().size.y
	options.hide()
	splash_layer.show()
	
	
	jobs_option.pressed.connect(jobs_pressed)
	settings_option.pressed.connect(settings_pressed)
	extras_option.pressed.connect(extras_pressed)
	

func _process(delta: float) -> void:
	
	if InputController.any() and state == States.SPLASHSCREEN:
		transition_to_menu()


func transition_to_menu() -> void:
	state = States.MENU
	splash_layer.hide()
	options.show()
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(options, "position:y", options_target_y(), 0.5)

func options_target_y() -> float:
	
	
	return get_viewport_rect().size.y - margin_container.size.y


func jobs_pressed() -> void:
	print("jobs")
	pass;
	
func settings_pressed() -> void:
	print("settings")
	pass;
	
func extras_pressed() -> void:
	print("extras")
	pass;
