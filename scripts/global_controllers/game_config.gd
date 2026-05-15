extends Node

var config = ConfigFile.new()
const CONFIG_PATH = "user://config.ini"

# This doesn't really belong here, but since I needed the list of customizable binds
# I figured I'd also include the mapping for human-friendly names
const keybind_actions_dictionary: Dictionary[String, String] = {
	"Move Forward": "up",
	"Move Backwards": "down",
	"Move Left": "left",
	"Move Right": "right",
	"Jump": "jump",
	"Sprint": "sprint",
	"Crouch": "crouch",
	"Dash": "dash",

	"Fire Gun": "fire_primary",
	"Fire Rocket": "fire_rocket",
	"Reload Gun": "reload_primary",

	"Kick": "kick",
	"Launch Enemy": "launch_enemy",
}

func _ready() -> void:
	if !FileAccess.file_exists(CONFIG_PATH):
		InputMap.load_from_project_settings()
		for action in keybind_actions_dictionary.values():
			config.set_value("keybinds", action, InputMap.action_get_events(action))

		config.set_value("video", "resolution", DisplayServer.window_get_size())
		config.set_value("video", "fullscreen", DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)

		config.save(CONFIG_PATH)
	else:
		config.load(CONFIG_PATH)
		for action in keybind_actions_dictionary.values():
			InputMap.action_erase_events(action)
			for event in config.get_value("keybinds", action):
				InputMap.action_add_event(action, event)
		DisplayServer.window_set_size(config.get_value("video", "resolution"))
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if config.get_value("video", "fullscreen") else DisplayServer.WINDOW_MODE_WINDOWED)
		# TODO: sound settings

func save_keybinds(keybinds) -> void: # keybinds: Dictionary[String, Array[InputEvent]]
	# optionally, could just store the entire dictionary with a single key
	for action in keybinds:
		config.set_value("keybinds", action, keybinds[action])
	config.save(CONFIG_PATH)

func save_video_settings(resolution: Vector2i, fullscreen: bool) -> void:
	config.set_value("video", "resolution", resolution)
	config.set_value("video", "fullscreen", fullscreen)
	config.save(CONFIG_PATH)

func save_audio_settings(master_volume: float, music_volume: float, sfx_volume: float) -> void:
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.save(CONFIG_PATH)
