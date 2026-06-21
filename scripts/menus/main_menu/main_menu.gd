class_name MainMenu extends Control

enum States { SPLASHSCREEN, MENU, SCREEN }
var state: States = States.SPLASHSCREEN
@onready var splash_layer: Control = %SplashLayer
@onready var options: Control = %Options
@onready var screens: Control = %Screens
@onready var jobs_screen: Control = %JobsScreen
@onready var margin_container: MarginContainer = %MarginContainer
@onready var settings_screen: Control = %SettingsScreen
@onready var menu_screens: Control = %MenuScreens



@onready var jobs_option: Control = %JobsOption
@onready var login_option: Control = %LoginOption
@onready var settings_option: Control = %SettingsOption

@export var options_bar : Control;
@export var top_margin := 16.0

@onready var wage_backdrop: Node3D = $WageBackdropViewportContainer/WageBackdropViewport/WageBackdrop


var current_screen: Control = null
var current_option_index: int = -1

const SPLASH_FADE_DURATION : float = 0.3;

var options_tween : Tween;
var screen_tween : Tween;
var splash_tween : Tween;

func options_target_y_bottom() -> float:
	return get_viewport_rect().size.y - margin_container.size.y

func screen_y() -> float:
	return options.position.y + margin_container.size.y

func _ready() -> void:
	
	MenuController.main_menu = self;
	
	await get_tree().process_frame
	options.position.y = get_viewport_rect().size.y
	screens.position.y = get_viewport_rect().size.y
	options.hide()
	screens.hide()
	fade_in_splash();

	jobs_option.pressed.connect(func(): select_option(jobs_screen, 0))
	settings_option.pressed.connect(func(): select_option(settings_screen, 1))
	login_option.pressed.connect(func(): 
		
		if ServerController.is_logged_in():
			
			GameController.confirm_popup("Do you want to log out?", 
				func():
					ServerController.logout();
			)
		else:
			ServerController.show_login_prompt();
		)

func _process(delta: float) -> void:
	
	if state == States.SPLASHSCREEN and (!options_tween or !options_tween.is_running()) and (InputController.any_just_pressed() and !InputController.escape()):
		transition_to_menu()

	if InputController.escape():
		go_back()

	if state == States.SCREEN or state == States.MENU:
		screens.position.y = screen_y()

func go_back() -> void:
	
	
	match state:
		States.SCREEN:
			
			
			#If the screen itself has something that accepts escape
			if current_screen.go_back():
				return
	
			state = States.MENU
			
			var screen_to_hide = current_screen
			current_screen = null
			current_option_index = -1
			
			_kill_screen_tween()
			_kill_options_tween()
				
			options_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
			options_tween.tween_property(options, "position:y", options_target_y_bottom(), 0.4)
			await options_tween.finished
			
			
			for screen in screens.get_children():
				screen.position.x = 0
			
			screen_to_hide.hide()
			
		States.MENU:
			
			_kill_screen_tween()
			_kill_options_tween()
			
			for screen in screens.get_children():
				screen.position.x = 0
				screen.hide()
				
			state = States.SPLASHSCREEN
			
			options_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
			options_tween.tween_property(options, "position:y", get_viewport_rect().size.y, 0.4)
			
			await options_tween.finished
			options.hide()
			fade_in_splash();

			
		States.SPLASHSCREEN:
			
			GameController.confirm_popup("Do you want to quit to desktop?", 
				func(): 
					get_tree().quit()
			)
			
			# TODO: show "quit game?" prompt
			pass

func transition_to_menu() -> void:
	
	if GameController.is_confirming() : return;
	
	state = States.MENU
	fade_out_splash()
	options.show()
	_kill_options_tween()
	options_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	options_tween.tween_property(options, "position:y", options_target_y_bottom(), 0.5)

func select_option(screen: Control, option_index: int) -> void:
	
	if current_screen == screen:
		return
	
	match state:
		States.MENU:
			_open_screen(screen, option_index)
			
		States.SCREEN:
			_slide_to_screen(screen, option_index)

func _open_screen(screen: Control, option_index: int) -> void:
	state = States.SCREEN
	current_screen = screen
	current_option_index = option_index

	screen.position.x = 0  # ensure clean position before showing
	screens.position.y = options_target_y_bottom()
	screens.show()
	screen.show()

	_kill_options_tween()
	options_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	options_tween.tween_property(options, "position:y", top_margin, 0.4)
	options_tween.parallel().tween_method(
		func(y: float): screens.position.y = screen_y(),
		screens.position.y, 0.0, 0.4
	)

func _slide_to_screen(new_screen: Control, new_index: int) -> void:
	var viewport_width = get_viewport_rect().size.x
	var direction = 1 if new_index > current_option_index else -1

	# If a slide is already in progress, snap the current one instantly
	_kill_screen_tween()
	current_screen.position.x = 0

	new_screen.position.x = viewport_width * direction
	new_screen.show()

	screen_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	screen_tween.set_parallel(true)
	screen_tween.tween_property(current_screen, "position:x", -viewport_width * direction, 0.4)
	screen_tween.tween_property(new_screen, "position:x", 0.0, 0.4)

	var old_screen = current_screen;
	current_screen = new_screen
	current_option_index = new_index
	
	await screen_tween.finished
	old_screen.hide()
	current_screen.position.x = 0


#region splash fade

func fade_in_splash() -> void:
	kill_splash_tween()
	splash_layer.show()
	splash_layer.modulate.a = 0.0
	splash_tween = create_tween()
	splash_tween.tween_property(splash_layer, "modulate:a", 1.0, SPLASH_FADE_DURATION)

func fade_out_splash() -> void:
	kill_splash_tween()
	splash_tween = create_tween()
	splash_tween.tween_property(splash_layer, "modulate:a", 0.0, SPLASH_FADE_DURATION)
	await splash_tween.finished
	splash_layer.hide()

func kill_splash_tween() -> void:
	if splash_tween and splash_tween.is_running():
		splash_tween.kill()
	splash_tween = null

#endregion


#region kill tweens

func _kill_options_tween() -> void:
	if options_tween and options_tween.is_running():
		options_tween.kill()
	options_tween = null

func _kill_screen_tween() -> void:
	if screen_tween and screen_tween.is_running():
		screen_tween.kill()
	screen_tween = null


#endregion
