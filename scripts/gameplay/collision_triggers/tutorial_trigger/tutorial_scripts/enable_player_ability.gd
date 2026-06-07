class_name EnablePlayerAbility extends TutorialScript

@export_enum("dash", "slide", "telekinesis") var ability : String = "dash";

func execute() -> void:
	LevelController.player_abilities[ability] = true;
