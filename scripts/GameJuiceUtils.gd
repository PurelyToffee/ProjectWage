extends Node

func hit_stop(timeScale : float = 0.1, duration : float = 1.) -> void:
	Engine.time_scale = timeScale;
	await get_tree().create_timer(duration * timeScale).timeout
	Engine.time_scale = 1.;
