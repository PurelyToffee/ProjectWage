extends ExtrasScreen

@export var entries : Array[ExtrasImages];

@onready var texture_rect: TextureRect = %TextureRect
@onready var credits_label: PanelContainer = %CreditsLabel


@onready var arrow_back: PanelContainer = %ArrowBack
@onready var arrow_forward: PanelContainer = %ArrowForward

var current = 0;

func _ready() -> void:
	load_image();
	
	arrow_back.pressed.connect(previous_image)
	arrow_forward.pressed.connect(next_image)
	
	hide_button(arrow_back);

func load_image(index : int = current) -> void:
	
	var entry := entries[index];
	
	texture_rect.texture = entry.image;
	texture_rect.expand_mode = entry.scale
	credits_label.get_node("MarginContainer/Label").text = entry.description;
	credits_label.link = entry.link;
	
	credits_label._on_button_mouse_exited()
	

func hide_button(button : Control) -> void:
	button.modulate.a = 0;
	button.button.mouse_filter = Control.MOUSE_FILTER_IGNORE

func show_button(button : Control) -> void:
	button.modulate.a = 1;
	button.button.mouse_filter = Control.MOUSE_FILTER_STOP

func next_image() -> void:
	
	current += 1;
	
	show_button(arrow_back)
	show_button(arrow_forward)
	
	if current == entries.size() - 1: hide_button(arrow_forward)

	
	load_image();
	
func previous_image() -> void:
	
	current -= 1;
	if current < 0 : current += entries.size()
	
	show_button(arrow_back)
	show_button(arrow_forward)
	
	if current == 0: hide_button(arrow_back)
		
	load_image();
