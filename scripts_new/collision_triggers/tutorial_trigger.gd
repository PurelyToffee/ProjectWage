extends Area2D
class_name TutorialTrigger

@export var tutorial_scene: PackedScene
var triggered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if triggered:
		return
	if LevelController.tutorial_open:
		return
	if not body.is_in_group("player"):
		return
	if tutorial_scene == null:
		return

	triggered = true
	monitoring = false
	LevelController.set_tutorial_open(true)
	LevelController.freeze_game()
	LevelController.freeze_timer()

	var tutorial = tutorial_scene.instantiate()
	get_tree().current_scene.add_child(tutorial)