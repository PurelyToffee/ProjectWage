class_name InputComponent extends Node

var input_dir : Vector2 = Vector2.ZERO;
var jump_buffer : float = 0.;

const JUMP_BUFFER_TIME : float = 0.2;

var controller_target_look : Vector2 = Vector2.ZERO;

func update(delta: float) -> void:
	
	jump_buffer = clampf(jump_buffer - delta, 0, JUMP_BUFFER_TIME)
	if Input.is_action_just_pressed("jump") : jump_buffer = JUMP_BUFFER_TIME;
	
	input_dir = Vector2.ZERO if LevelController.player_frozen else Input.get_vector("left", "right", "up", "down").normalized()
	controller_target_look = Vector2.ZERO if LevelController.player_frozen else Input.get_vector("look_left", "look_right", "look_down", "look_up")
	
	pass

func fire_primary() -> bool:
	return !LevelController.player_frozen and Input.is_action_pressed("fire_primary")

func reload_primary() -> bool:
	return !LevelController.player_frozen and Input.is_action_pressed("reload_primary")

func launch_enemy() -> bool:
	return !LevelController.player_frozen and Input.is_action_just_pressed("launch_enemy")

func do_kick() -> bool:
	return !LevelController.player_frozen and Input.is_action_just_pressed("kick")

func fire_rocket() -> bool:
	return !LevelController.player_frozen and Input.is_action_just_pressed("fire_rocket")

func just_crouched() -> bool:
	return !LevelController.player_frozen and Input.is_action_just_pressed("crouch");
	
func is_crouching() -> bool:
	return !LevelController.player_frozen and Input.is_action_pressed("crouch");

func jump_just_pressed() -> bool:
	
	return !LevelController.player_frozen and Input.is_action_just_pressed("jump");
	
func jump_pressed() -> bool:
	return !LevelController.player_frozen and jump_buffer > 0.;
	
func reset_jump_buffer() -> void:
	jump_buffer == 0.

func capture_mouse(event : InputEvent) -> void:
	
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
