class_name TutorialTrigger extends CollisionTrigger

@export var tutorial_scene: PackedScene
@export var pages: Array[TutorialPageData] = []

func trigger(body: Node) -> void:
	if !active:
		return
		
	if not body.is_in_group("player"):
		return

	LevelController.player.force_uncrouch();
	LevelController.open_tutorial(tutorial_scene, pages);

	active = false
