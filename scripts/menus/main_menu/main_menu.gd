extends Control

@onready var main_menu_container: Control = %MainMenuContainer
@onready var levels_container: Control = %LevelsCenterContainer
@onready var settings_container: Control = %SettingsContainer
@onready var back_button: Button = %BackButton

@onready var menu_stack: Array[Control] = [main_menu_container]

func set_menu(menu: Control, push_to_stack: bool = true) -> void:
	menu_stack.back().hide()
	menu.show()
	if push_to_stack:
		menu_stack.push_back(menu)
		back_button.show()

func return_to_main_menu() -> void:
	menu_stack.back().hide()
	menu_stack = [main_menu_container]
	menu_stack.back().show()
	back_button.hide()

func _on_back_button_pressed() -> void:
	if menu_stack.size() <= 1: return
	if menu_stack.back().has_method("_on_back_button_pressed"):
		if !menu_stack.back()._on_back_button_pressed():
			return
	set_menu(menu_stack[menu_stack.size() - 2], false)
	menu_stack.pop_back()
	if menu_stack.size() <= 1:
		back_button.hide()

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
