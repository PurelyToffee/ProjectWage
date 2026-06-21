extends Node3D

@onready var world_environment = %WorldEnvironment

func _process(delta: float) -> void:

	if GameController.game_state == GameController.game_states.main_menu and world_environment.environment == null:
		visible = true;
		world_environment.environment = load("uid://dy6udaxbuduwv")
	elif GameController.game_state != GameController.game_states.main_menu and world_environment.environment != null:
		visible = false;
		world_environment.environment = null;
