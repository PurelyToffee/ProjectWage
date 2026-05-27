extends Control

@onready var main_menu_container: Control = %MainMenuContainer
@onready var levels_container: Control = %LevelsCenterContainer
@onready var settings_container: Control = %SettingsContainer
@onready var back_button: Button = %BackButton

@onready var menu_stack: Array[Control] = [main_menu_container]

@onready var levels_list: Control = %LevelsList
@onready var level_button_scene = preload("res://scripts/menus/main_menu/level_button.tscn")

@onready var login_btn = %Login
@onready var logout_btn = %Logout
@onready var label = %Username
@onready var website: Button = %Website


var confirm_dialog: ConfirmationDialog

func _ready() -> void:
	
	ServerController.logged_in.connect(_on_logged_in)
	ServerController.logged_out.connect(_on_logged_out)
	login_btn.pressed.connect(_on_login_pressed)
	website.pressed.connect(_on_website_pressed)
	
	confirm_dialog = ConfirmationDialog.new()
	confirm_dialog.dialog_text = "Are you sure you want to log out?"
	add_child(confirm_dialog)
	
	logout_btn.pressed.connect(_on_logout_pressed)
	confirm_dialog.confirmed.connect(_on_logout_confirmed)
	
	
	if ServerController.current_token != "":
		_on_logged_in(ServerController.current_username)
	else:
		_on_logged_out()

func _on_login_pressed():
	ServerController.show_login_prompt()

func _on_logout_pressed():
	confirm_dialog.popup_centered()

func _on_logout_confirmed():
	ServerController.logout()

func _on_website_pressed():
	OS.shell_open(ServerController.SERVER_DOMAIN)

func _on_logged_in(username: String):
	label.text = username
	login_btn.visible = false
	logout_btn.visible = true

func _on_logged_out():
	label.text = ""
	login_btn.visible = true
	logout_btn.visible = false

var level_containers = {};

func _load_levels_and_scores() -> void:
	for item in levels_list.get_children():
		item.queue_free()
	
	level_containers.clear();
	
	for level_id in MenuController.levels.keys():
		var level = MenuController.levels[level_id]
		
		level_containers[level.name] = level_button_scene.instantiate();
		
		var button = level_containers[level.name].find_child("PlayButton")
		button.text = level["name"]
		button.pressed.connect(_play_level.bind(level_id))
		if (level_id != 0): 
			button.disabled = true
		levels_list.add_child(level_containers[level.name])
		
		var scores = GameData.data["level_scores"][level_id] if GameData.data["level_scores"].has(level_id) else null
		update_level_container(level_containers[level.name], scores);
		
		
func update_level_container(container : BoxContainer, scores) -> void:
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
	_load_levels_and_scores();

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
