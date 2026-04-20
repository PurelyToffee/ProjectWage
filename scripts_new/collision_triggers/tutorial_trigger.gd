class_name TutorialTrigger extends CollisionTrigger

@export var tutorial_scene: PackedScene


func trigger(body: Node) -> void:
	if !active:
		return
		
	if not body.is_in_group("player"):
		return

	LevelController.freeze_game()
	LevelController.freeze_timer()

	LevelController.set_tutorial_open(true)
	
	var tutorial = tutorial_scene.instantiate()
	get_tree().current_scene.add_child(tutorial)

	active = false
