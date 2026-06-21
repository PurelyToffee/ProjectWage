extends Node3D

@onready var world_environment = %WorldEnvironment
@onready var animation_player: AnimationPlayer = $MenuAnimationWageNewTryPleaseGod2/AnimationPlayer

func _process(delta: float) -> void:

	if GameController.game_state == GameController.game_states.main_menu and world_environment.environment == null:
		visible = true;
		world_environment.environment = load("uid://dy6udaxbuduwv")
	elif GameController.game_state != GameController.game_states.main_menu and world_environment.environment != null:
		visible = false;
		world_environment.environment = null;

func play_start() -> void:
	animation_player.play_start();
