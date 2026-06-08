extends MenuScreen

@onready var map_root: Control = %MapRoot

const ZOOM_MAX = 3.0
const ZOOM_STEP = 0.1

var zoom: float = 1.0
var is_dragging: bool = false

@onready var map_texture: TextureRect = %MapTexture

var ZOOM_MIN: float = 1.0

func _ready() -> void:
	await super._ready();
	
	# Set initial zoom to fill
	var map_size = map_texture.size
	var zoom_fit_x = sub_viewport.size.x / map_size.x
	var zoom_fit_y = sub_viewport.size.y / map_size.y
	ZOOM_MIN = max(zoom_fit_x, zoom_fit_y)
	zoom = ZOOM_MIN
	map_root.scale = Vector2(zoom, zoom)
	_clamp_position()

func update() -> void:
	print("lol")
	map_texture.position = Vector2.ZERO

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_set_zoom(zoom + ZOOM_STEP, get_local_mouse_position())
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_set_zoom(zoom - ZOOM_STEP, get_local_mouse_position())
		elif event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = event.pressed

	if event is InputEventMouseMotion and is_dragging:
		map_root.position += event.relative
		_clamp_position()

func _set_zoom(new_zoom: float, anchor: Vector2) -> void:
	new_zoom = clamp(new_zoom, ZOOM_MIN, ZOOM_MAX)
	var local_anchor = (anchor - map_root.position) / zoom
	zoom = new_zoom
	map_root.scale = Vector2(zoom, zoom)
	map_root.position = anchor - local_anchor * zoom
	
	_clamp_position()

func _clamp_position() -> void:
	var container_size = sub_viewport.get_visible_rect().size
	var map_size = map_texture.size * zoom

	var min_x = container_size.x - map_size.x
	var min_y = container_size.y - map_size.y

	map_root.position.x = clamp(map_root.position.x, min_x, 0.0)
	map_root.position.y = clamp(map_root.position.y, min_y, 0.0)
	
