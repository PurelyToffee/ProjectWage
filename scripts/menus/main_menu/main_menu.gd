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

@onready var extras_screen: MenuScreen = $Screens/ExtrasScreen


@onready var jobs_option: Control = %JobsOption
@onready var login_option: Control = %LoginOption
@onready var settings_option: Control = %SettingsOption
@onready var extras_option: MenuOption = %ExtrasOption

@onready var splash_label: Label = %SplashLabel

@export var options_bar : Control;
@export var top_margin := 16.0

@onready var wage_backdrop: Node3D = $WageBackdropViewportContainer/WageBackdropViewport/WageBackdrop

@onready var intro_animation: Control = %IntroAnimation
@onready var lighter_sparks: AnimatedSprite2D = %LighterSparks

@onready var logo: TextureRect = %Logo


var current_screen: Control = null
var current_option_index: int = -1

const SPLASH_FADE_DURATION : float = 0.3;
@onready var intro_timer: Timer = %IntroTimer

var options_tween : Tween;
var screen_tween : Tween;
var splash_tween : Tween;
var logo_tween : Tween;

var intro_finished : bool = false;

#region bobbing
const BOB_AMPLITUDE : float = 8.0;
const BOB_DURATION : float = 1.4;

var logo_bob_tween : Tween;
var splash_label_bob_tween : Tween;
#endregion

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
	splash_layer.hide()

	jobs_option.pressed.connect(func(): select_option(jobs_screen, 0))
	settings_option.pressed.connect(func(): select_option(settings_screen, 1))
	extras_option.pressed.connect(func(): select_option(extras_screen, 2))
	
	login_option.pressed.connect(func(): 
		
		if ServerController.is_logged_in():
			
			GameController.confirm_popup("Do you want to log out?", 
				func():
					ServerController.logout();
			)
		else:
			ServerController.show_login_prompt();
		)

	_play_intro_animation()
	
	_start_bobbing(logo, logo_bob_tween)
	_start_bobbing(splash_label, splash_label_bob_tween)

func _process(delta: float) -> void:
	
	if not intro_finished:
		return
	
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
			fade_out_logo()

			
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
	fade_in_logo()
	
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


#region intro animation

func _play_intro_animation() -> void:
	
	intro_animation.show();
	
	await intro_timer.timeout
	
	lighter_sparks.play()
	
	await lighter_sparks.animation_finished
	
	intro_animation.hide()
	wage_backdrop.play_start()
	intro_finished = true
	fade_in_splash()

#endregion


#region bobbing

func _start_bobbing(node: Control, tween: Tween) -> void:
	var base_y := node.position.y
	var full_cycle := BOB_DURATION * 4.0
	
	var bob_tween := create_tween().set_loops()
	bob_tween.tween_method(
		func(t: float): node.position.y = base_y + sin(t * TAU) * BOB_AMPLITUDE,
		0.0, 1.0, full_cycle
	)
	
	if node == logo:
		logo_bob_tween = bob_tween
	elif node == splash_label:
		splash_label_bob_tween = bob_tween

#endregion


#region logo fade

func fade_in_logo() -> void:
	kill_logo_tween()
	logo.modulate.a = 0.0
	logo_tween = create_tween()
	logo_tween.tween_property(logo, "modulate:a", 1.0, SPLASH_FADE_DURATION)

func fade_out_logo() -> void:
	kill_logo_tween()
	logo_tween = create_tween()
	logo_tween.tween_property(logo, "modulate:a", 0.0, SPLASH_FADE_DURATION)

func kill_logo_tween() -> void:
	if logo_tween and logo_tween.is_running():
		logo_tween.kill()
	logo_tween = null

#endregion


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
