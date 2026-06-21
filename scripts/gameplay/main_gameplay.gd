class_name MainGameplay extends Node3D

@onready var gameplay_hud: CanvasLayer = %GameplayHUD
@onready var gameplay_viewport_container: SubViewportContainer = %GameplayViewportContainer
@onready var gameplay_viewport: SubViewport = %GameplayViewport

func _ready() -> void:
	
	LevelController.gameplay_node = self;
	LevelController.level_start_hud = LevelController.create_menu(LevelController.LEVEL_START_HUD)
	
	LevelController.set_timer(0)
	LevelController.reset_score()
	LevelController.level_state = LevelController.level_states.START
	
	LevelController.freeze_game()
	LevelController.freeze_timer()
	LevelController.freeze_player()
	
	gameplay_hud.viewport_scale = gameplay_viewport_container.stretch_shrink;
	gameplay_viewport_container.stretch_shrink = GameConfig.config.get_value("video", "pixelization")
	pass


func load_level(level : PackedScene) -> void:
	
	var l = level.instantiate()
	
	await ready
	gameplay_viewport.add_child(l);
