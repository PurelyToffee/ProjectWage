extends Control

@onready var main_menu_container: Control = %MainMenuContainer
@onready var levels_container: Control = %LevelsCenterContainer
@onready var settings_container: Control = %SettingsContainer

@onready var current_menu: Control = main_menu_container

func set_menu(menu: Control) -> void:
	if current_menu != null:
		current_menu.hide()
	menu.show()
	current_menu = menu

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
