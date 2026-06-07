extends Camera3D

var main_camera: Camera3D

func _process(_delta: float) -> void:
	main_camera = LevelController.player_camera
	global_transform = main_camera.global_transform
	fov = main_camera.fov
	near = main_camera.near
	far = main_camera.far
