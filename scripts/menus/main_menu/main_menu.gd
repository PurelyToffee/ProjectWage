extends Control

@onready var main_menu_container: Control = %MainMenuContainer
@onready var levels_container: Control = %LevelsCenterContainer
@onready var settings_container: Control = %SettingsContainer
@onready var back_button: Button = %BackButton

@onready var menu_stack: Array[Control] = [main_menu_container]

@onready var levels_list: Control = %LevelsList
@onready var level_button_scene = preload("res://scripts/menus/main_menu/level_button.tscn")


func _ready() -> void:
	_load_levels_and_scores()

func _load_levels_and_scores() -> void:
	for item in levels_list.get_children():
		item.queue_free()

	for level_id in MenuController.levels.keys():
		var level = MenuController.levels[level_id]
		var container = level_button_scene.instantiate()
		var button = container.find_child("PlayButton")
		button.text = level["name"]
		button.pressed.connect(_play_level.bind(level_id))
		if (level_id != 0): # TODO: change this when more levels are available
			button.disabled = true
		levels_list.add_child(container)
		
		var scores = GameData.data["level_scores"][level_id] if GameData.data["level_scores"].has(level_id) else null
		container.find_child("BestTime").text = LevelController.time_to_str(scores["time"]) if scores else "--:--:---"
		container.find_child("BestScore").text = "%08d" % (scores["score"] if scores else 0)
		container.find_child("BestGrade").text = scores["grade"] if scores else "-"

func set_menu(menu: Control, push_to_stack: bool = true) -> void:
	menu_stack.back().hide()
	menu.show()
	if push_to_stack:
		menu_stack.push_back(menu)
		back_button.show()

func return_to_main_menu() -> void:
	_load_levels_and_scores()
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

func _play_level(id: int) -> void:
	var level = MenuController.levels[id]
	LevelController.current_level_id = id
	level["load"].call()
	MenuController.quit()

#endregion (Levels)
