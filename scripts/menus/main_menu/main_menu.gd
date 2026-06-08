# main_menu.gd
extends Control

enum States { SPLASHSCREEN, MENU, SCREEN }
var state: States = States.SPLASHSCREEN

@onready var splash_layer: Control = %SplashLayer
@onready var options: Control = %Options
@onready var screens: Control = %Screens
@onready var jobs_screen: Control = %JobsScreen
@onready var margin_container: MarginContainer = %MarginContainer
@onready var settings_option: Control = %SettingsOption
@onready var settings_screen: Control = %SettingsScreen


@onready var menu_screens: Control = %MenuScreens

@onready var jobs_option: Control = %JobsOption

@export var top_margin := 16.0;

var current_screen: Control = null
var current_option_index: int = -1

func options_target_y_bottom() -> float:
	return get_viewport_rect().size.y - margin_container.size.y
	
func screen_y() -> float:
	return options.position.y + margin_container.size.y

func _ready() -> void:
	await get_tree().process_frame
	options.position.y = get_viewport_rect().size.y
	screens.position.y = get_viewport_rect().size.y
	options.hide()
	screens.hide()
	splash_layer.show()
	
	# connect your options here
	jobs_option.pressed.connect(func(): select_option(jobs_screen, 0))
	settings_option.pressed.connect(func(): select_option(settings_screen, 1))

func _process(delta: float) -> void:
	if InputController.any() and state == States.SPLASHSCREEN:
		transition_to_menu()
	if state == States.SCREEN or state == States.MENU:
		screens.position.y = options.position.y + margin_container.size.y

func transition_to_menu() -> void:
	state = States.MENU
	splash_layer.hide()
	options.show()
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(options, "position:y", options_target_y_bottom(), 0.5)


func select_option(screen: Control, option_index: int) -> void:
	if current_screen == screen:
		return
	if state == States.MENU:
		_open_screen(screen, option_index)
	elif state == States.SCREEN:
		_slide_to_screen(screen, option_index)

func _open_screen(screen: Control, option_index: int) -> void:
	state = States.SCREEN
	current_screen = screen
	current_option_index = option_index
	
	screens.position.y = options_target_y_bottom()
	screens.show()
	screen.show()
	
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(options, "position:y", top_margin, 0.4)
	tween.parallel().tween_method(
		func(y: float): screens.position.y = screen_y(),
		screens.position.y, 0.0, 0.4
	)

func _slide_to_screen(new_screen: Control, new_index: int) -> void:
	var viewport_width = get_viewport_rect().size.x
	var direction = 1 if new_index > current_option_index else -1
	
	new_screen.position.x = viewport_width * direction
	new_screen.show()
	
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.set_parallel(true)
	tween.tween_property(current_screen, "position:x", -viewport_width * direction, 0.4)
	tween.tween_property(new_screen, "position:x", 0.0, 0.4)
	await tween.finished
	
	current_screen.hide()
	current_screen.position.x = 0
	current_screen = new_screen
	current_option_index = new_index
