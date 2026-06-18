class_name MenuScreen extends Control

@onready var sub_viewport: SubViewport = %SubViewport

@export var main_menu : MainMenu;

var viewport_size;
var options_bar_height;

func _ready() -> void:
	await get_tree().process_frame
	viewport_size = get_viewport().get_visible_rect().size
	options_bar_height = main_menu.options_bar.options_size.y + main_menu.top_margin

	# Resize the SubViewport
	sub_viewport.size = Vector2i(viewport_size.x, viewport_size.y - options_bar_height)
	update();


func go_back() -> bool:
	return false;

func update() -> void:
	pass;
