extends MenuScreen

@onready var map_root: Control = %MapRoot

var ZOOM_MIN: float = 1.0
const ZOOM_MAX := 1.
const ZOOM_STEP := 0.4

var zoom: float = 1.0
var target_zoom : float = 1.0;
var is_dragging: bool = false

var curr_anchor : Vector2;
var local_anchor : Vector2;

@onready var map_texture: TextureRect = %MapTexture
@onready var loading_screen: Control = %LoadingScreen


func _ready() -> void:
	await super._ready();
	
	# Set initial zoom to fill
	var map_size = map_texture.size
	var zoom_fit_x = sub_viewport.size.x / map_size.x
	var zoom_fit_y = sub_viewport.size.y / map_size.y
	ZOOM_MIN = max(zoom_fit_x, zoom_fit_y) + 0.1
	zoom = ZOOM_MIN;
	target_zoom = ZOOM_MIN;
	map_root.scale = Vector2(zoom, zoom)
	_clamp_position()

func update() -> void:
	map_texture.position = Vector2.ZERO

func _process(delta: float) -> void:
	
	zoom = lerpf(zoom, target_zoom, delta * 16.);
	update_zoom();

func update_zoom() -> void:
	
	map_root.scale = Vector2(zoom, zoom)
	map_root.position = curr_anchor - local_anchor * zoom
	_clamp_position()


func _input(event: InputEvent) -> void:
	
	if main_menu.current_screen != self or GameController.is_confirming():
		return;
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = event.pressed

	if event is InputEventMouseMotion and is_dragging:
		var old_position = map_root.position
		map_root.position += event.relative
		_clamp_position()
		var actual_delta = map_root.position - old_position
		curr_anchor += actual_delta  # only move anchor by what the map actually moved

func _set_zoom(new_zoom: float, anchor: Vector2) -> void:
	
	new_zoom = clamp(new_zoom, ZOOM_MIN, ZOOM_MAX)
	curr_anchor = anchor
	local_anchor = (anchor - map_root.position) / zoom  # capture at current zoom
	target_zoom = new_zoom


func _clamp_position() -> void:
	var container_size = sub_viewport.get_visible_rect().size
	var map_size = map_texture.size * zoom

	var min_x = container_size.x - map_size.x
	var min_y = container_size.y - map_size.y

	map_root.position.x = clamp(map_root.position.x, min_x, 0.0)
	map_root.position.y = clamp(map_root.position.y, min_y, 0.0)
	
