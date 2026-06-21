class_name MenuScreen extends Control

@onready var sub_viewport: SubViewport = %SubViewport

@export var main_menu : MainMenu;

@onready var container: SubViewportContainer = %Container

@onready var credits: ExtrasButton = %Credits
@onready var concepts: ExtrasButton = %Concepts
@onready var fanarts: ExtrasButton = %Fanarts
@onready var contents: MarginContainer = %Contents

@onready var credits_screen: ExtrasScreen = %CreditsScreen
@onready var fanarts_screen: ExtrasScreen = %FanartsScreen

var viewport_size;
var options_bar_height;

var selected : ExtrasButton;

func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	viewport_size = get_viewport().get_visible_rect().size
	options_bar_height = main_menu.options_bar.options_size.y + main_menu.top_margin

	# Resize the SubViewport
	sub_viewport.size = Vector2i(viewport_size.x, viewport_size.y - options_bar_height)
	update();

	selected = credits;
	


func go_back() -> bool:
	return false;

func update() -> void:
	pass;


func hide_contents() -> void:
	for c in contents.get_children():
		c.hide();

func _on_credits_pressed() -> void:
	
	selected = credits;
	
	hide_contents()
	credits_screen.show();
	
	container.texture_filter = credits_screen.filter_type;
	
	pass # Replace with function body.


func _on_concepts_pressed() -> void:
	
	selected = concepts;

	hide_contents()
	#concepts.show()
	pass # Replace with function body.


func _on_fanart_pressed() -> void:
	
	selected = fanarts;

	hide_contents()
	fanarts_screen.show()
	container.texture_filter = fanarts_screen.filter_type;
	pass # Replace with function body.
