class_name InputComponent extends Node

var input_dir : Vector2 = Vector2.ZERO;
var jump_buffer : float = 0.;

const JUMP_BUFFER_TIME : float = 0.2;

var controller_target_look : Vector2 = Vector2.ZERO;

func update(delta: float) -> void:
	
	jump_buffer = clamp(jump_buffer, 0, jump_buffer - delta);
	
	input_dir = Input.get_vector("left", "right", "up", "down").normalized()
	jump_buffer = max(jump_buffer, int(Input.is_action_just_pressed("jump")) * JUMP_BUFFER_TIME);
	
	controller_target_look = Input.get_vector("look_left", "look_right", "look_down", "look_up")
	
	pass


func do_kick() -> bool:
	return Input.is_action_just_pressed("kick")

func fire_rocket() -> bool:
	return Input.is_action_just_pressed("fire_rocket")

func just_crouched() -> bool:
	return Input.is_action_just_pressed("crouch");
	
func is_crouching() -> bool:
	return Input.is_action_pressed("crouch");

func jump_just_pressed() -> bool:
	
	print(jump_buffer)
	
	return jump_buffer > 0.;
	
func jump_pressed() -> bool:
	return Input.is_action_pressed("jump");

func capture_mouse(event : InputEvent) -> void:
	
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
