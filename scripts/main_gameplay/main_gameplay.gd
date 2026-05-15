class_name MainGameplay extends Node3D

@onready var gameplay_hud: CanvasLayer = %GameplayHUD
@onready var gameplay_viewport_container: SubViewportContainer = %GameplayViewportContainer
@onready var gameplay_viewport: SubViewport = %GameplayViewport

func _ready() -> void:
	
	LevelController.gameplay_node = self;
	
	# TODO: can this be improved?
	LevelController.close_menu() # without this, most controls don't work after returning to menu
	LevelController.set_timer(0)
	LevelController.reset_score()
	
	gameplay_hud.viewport_scale = gameplay_viewport_container.stretch_shrink;
	pass


func set_level(level : PackedScene) -> void:
	
	var l = level.instantiate()
	
	await ready
	gameplay_viewport.add_child(l);
