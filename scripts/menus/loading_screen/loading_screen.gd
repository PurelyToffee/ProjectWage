class_name LoadingScreen extends Control

@onready var loading_group: CanvasGroup = %LoadingGroup

func _ready() -> void:
	GameController.loading_screen = self

func start(on_visible: Callable) -> void:
	visible = true
	loading_group.material.set_shader_parameter("alpha", 0.0)
	var tween = create_tween()
	tween.tween_method(func(a: float):
		loading_group.material.set_shader_parameter("alpha", a)
	, 0.0, 1.0, 1.)
	
	tween.tween_callback(
		func(): 
			var min_time := get_tree().create_timer(0.5).timeout
			await min_time
			on_visible.call()
	)

func load(on_loaded: Callable) -> void:
	
	on_loaded.call()

func finish() -> void:
	
	var tween = create_tween()
	tween.tween_method(func(a: float):
		loading_group.material.set_shader_parameter("alpha", a)
	, 1.0, 0.0, 1.)
	tween.tween_callback(func():
		visible = false
	)
	
