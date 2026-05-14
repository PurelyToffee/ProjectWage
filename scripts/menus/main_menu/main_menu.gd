extends Control

@onready var levels_container: Control = %LevelsCenterContainer
@onready var settings_container: Control = %SettingsContainer
@onready var keybindings_container: Control = %KeyBindingsScrollContainer

@onready var resolution_picker: OptionButton = %ResolutionPicker
@onready var fullscreen_button: CheckButton = %FullscreenButton

var current_menu: Control = null

#region Init and Auxiliary
func _ready() -> void:
	_init_settings_menu()
	_init_keybinds_menu()

func set_menu(menu: Control) -> void:
	if current_menu != null:
		current_menu.hide()
	menu.show()
	current_menu = menu
#endregion (Init and Auxiliary)
#region MainMenu
func _on_play_pressed() -> void:
	set_menu(levels_container)

func _on_settings_pressed() -> void:
	set_menu(settings_container)

func _on_quit_pressed() -> void:
	get_tree().quit();

#endregion (MainMenu)
#region Levels
func _on_tutorial_pressed() -> void:
	MenuController.play_tutorial();
	
	MenuController.quit()
	
	pass;

func _on_level_1_pressed() -> void:
	pass # Replace with function body.

func _on_level_2_pressed() -> void:
	pass # Replace with function body.
#endregion (Levels)
#region Settings
func _init_settings_menu() -> void:
	fullscreen_button.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	var resolutions: Array[Vector2i] = [
		Vector2i(800, 600),
		Vector2i(1280, 720),
		Vector2i(1366, 768),
		Vector2i(1600, 900),
		Vector2i(1920, 1080),
		Vector2i(2560, 1440),
		Vector2i(3840, 2160),
	]

	# add current resolution if not on the list
	var current_res = DisplayServer.window_get_size()
	var idx = resolutions.find(current_res)
	if idx == -1:
		resolutions.insert(0, current_res);

	# only show compatible resolutions
	var monitor_size = DisplayServer.screen_get_size()
	for res in resolutions:
		if res.x <= monitor_size.x and res.y <= monitor_size.y:
			resolution_picker.add_item("%dx%d" % [res.x, res.y])
	resolution_picker.select(idx if idx != -1 else 0)

func _on_master_volume_change(value: float) -> void:
	pass # TODO

func _on_music_volume_change(value: float) -> void:
	pass # TODO

func _on_sfx_volume_change(value: float) -> void:
	pass # TODO

func _on_keybindings_pressed() -> void:
	set_menu(keybindings_container)

func _on_resolution_select(index: int) -> void:
	var resolution_str: String = resolution_picker.get_item_text(index)
	var split = resolution_str.split("x") # e.g. "1920x1080" -> ["1920", "1080"]
	DisplayServer.window_set_size(Vector2i(int(split[0]), int(split[1])));
	_save_video_settings()

func _on_fullscreen_toggle(toggled_on: bool) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if toggled_on else DisplayServer.WINDOW_MODE_WINDOWED)
	_save_video_settings()
#endregion (Settings)
#region Keybinds
@onready var keybind_scene = preload("uid://dsvyg3655eyx6")
@onready var keybinds_list = %KeyBindingsList

var currently_remapping: bool = false; # whether a keybind is currently being remapped
var remap_action: String;
var remap_button: Button;

# Just doing e.as_text() leads to ugly names
func _event_to_text(e: InputEvent):
		if e is InputEventKey:
			return OS.get_keycode_string(e.physical_keycode)
		elif e is InputEventMouseButton:
			return "Mouse %d" % e.button_index
		elif e is InputEventJoypadButton:
			return "Gamepad Button %d" % e.button_index
		elif e is InputEventJoypadMotion:
			var axis = e.axis
			var dir = e.axis_value
			var result = "Axis %d" % axis
			if axis == JOY_AXIS_LEFT_X:
				result = "Left Stick"
			elif axis == JOY_AXIS_LEFT_Y:
				result = "Left Stick"
			elif axis == JOY_AXIS_RIGHT_X:
				result = "Right Stick"
			elif axis == JOY_AXIS_RIGHT_Y:
				result = "Right Stick"

			if dir < 0:
				return result + " Left/Up"
			else:
				return result + " Right/Down"
		return e.as_text() # fallback

func _init_keybinds_menu() -> void:
	for item in keybinds_list.get_children():
		item.queue_free()

	for action in Config.keybind_actions_dictionary:
		var keybind_obj = keybind_scene.instantiate()
		var action_label = keybind_obj.find_child("ActionName")
		var primary_bind_button = keybind_obj.find_child("PrimaryBind")
		var secondary_bind_button = keybind_obj.find_child("SecondaryBind")
		
		action_label.text = action
		action = Config.keybind_actions_dictionary[action]
		var events = InputMap.action_get_events(action)
		if events.size() > 0:
			primary_bind_button.text = _event_to_text(events[0])
			primary_bind_button.set_meta("event", events[0])
			if events.size() > 1:
				secondary_bind_button.text = _event_to_text(events[1])
				secondary_bind_button.set_meta("event", events[1])
			else:
				secondary_bind_button.text = ""
		else:
			primary_bind_button.text = ""
		
		keybinds_list.add_child(keybind_obj)
		primary_bind_button.pressed.connect(_on_remap_button_press.bind(primary_bind_button, action))
		secondary_bind_button.pressed.connect(_on_remap_button_press.bind(secondary_bind_button, action))

func _on_remap_button_press(button: Button, action: String) -> void:
	currently_remapping = true
	remap_action = action
	remap_button = button
	button.text = "Awaiting input..."

func _input(event: InputEvent) -> void:
	if !currently_remapping or event is InputEventMouseMotion:
		return
	InputMap.action_erase_event(remap_action, remap_button.get_meta("event"))
	InputMap.action_add_event(remap_action, event)
	remap_button.text = _event_to_text(event)
	remap_button.set_meta("event", event)
	currently_remapping = false
	_save_keybinds()
	accept_event() # prevent event from passing on to other handlers

# In case we want an option to revert changes etc.
func _save_keybinds() -> void:
	var keybinds = {}
	for action in Config.keybind_actions_dictionary.values():
		keybinds[action] = InputMap.action_get_events(action)
	Config.save_keybinds(keybinds)

func _save_video_settings() -> void:
	# a bit redundant but whatever
	Config.save_video_settings(
		DisplayServer.window_get_size(),
		DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN,
	)

#endregion (Keybinds)
