extends Control

@onready var levels_container: Control = %LevelsCenterContainer
@onready var settings_container: Control = %SettingsContainer
@onready var resolution_picker: OptionButton = %ResolutionPicker
var current_menu: Control = null

#region Init and Auxiliary
var resolutions: Array[Vector2i] = [
	Vector2i(800, 600),
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160),
]

func _ready() -> void:
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

func set_menu(menu: Control) -> void:
	if current_menu != null:
		current_menu.hide()
	menu.show()
	current_menu = menu
	pass
#endregion (Init and Auxiliary)
#region MainMenu
func _on_play_pressed() -> void:
	set_menu(levels_container)

func _on_settings_pressed() -> void:
	set_menu(settings_container)

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
func _on_quit_pressed() -> void:
	get_tree().quit();

func _on_master_volume_change(value: float) -> void:
	pass # TODO

func _on_music_volume_change(value: float) -> void:
	pass # TODO

func _on_sfx_volume_change(value: float) -> void:
	pass # TODO

func _on_keybindings_pressed() -> void:
	pass #TODO

func _on_resolution_select(index: int) -> void:
	var resolution_str: String = resolution_picker.get_item_text(index)
	var split = resolution_str.split("x") # e.g. "1920x1080" -> ["1920", "1080"]
	DisplayServer.window_set_size(Vector2i(int(split[0]), int(split[1])));

func _on_fullscreen_toggle(toggled_on: bool) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if toggled_on else DisplayServer.WINDOW_MODE_WINDOWED)
#endregion (Settings)
