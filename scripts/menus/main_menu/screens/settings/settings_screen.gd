extends MenuScreen

@onready var settings_container: VBoxContainer = %SettingsContainer

func go_back() -> bool:
	return settings_container.go_back();
