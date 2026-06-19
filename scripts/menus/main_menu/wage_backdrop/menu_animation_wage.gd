extends Node3D

func _process(delta: float) -> void:
	visible = GameController.game_state == GameController.game_states.main_menu
