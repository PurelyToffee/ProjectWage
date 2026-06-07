extends Camera3D

func _process(delta: float) -> void:
	global_transform = LevelController.player_camera.global_transform;
