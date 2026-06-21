class_name MainMenuCanvas extends CanvasLayer

func _ready() -> void:
	GameController.main_hud = self;
