class_name TutorialTrigger extends CollisionTrigger

@export var tutorial_scene: PackedScene
@export var pages: Array[TutorialPageData] = []

@export var callback : TutorialScript = TutorialScript.new();

func trigger(body: Node) -> void:
	
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	match GameConfig.config.get_value("general", "tutorials"):
		
		GameConfig.TutorialSetting.DISABLED:
			return
			
		GameConfig.TutorialSetting.UNTIL_WIN:
			if GameData.is_level_passed(LevelController.current_level_id):
				return
				
		GameConfig.TutorialSetting.ALWAYS:
			pass
	
	if !overlaps_body(body) : return;
	
	if !active or LevelController.is_player_frozen():
		return
		
	if not body.is_in_group("player"):
		return

	LevelController.player.force_uncrouch();
	LevelController.open_tutorial(tutorial_scene, pages);

	callback.execute();

	active = false
