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
	gameplay_viewport_container.stretch_shrink = GameConfig.config.get_value("video", "pixelization")
	pass


func load_level(level : PackedScene) -> void:

	# Only await if _ready hasn't run yet; otherwise the 'ready' signal has
	# already fired and awaiting it would suspend here forever.
	if not is_node_ready():
		await ready

	# Remove the placeholder level baked into the scene (and any prior level)
	# so only the requested one is live in the viewport.
	for child in gameplay_viewport.get_children():
		gameplay_viewport.remove_child(child)
		child.queue_free()

	gameplay_viewport.add_child(level.instantiate());
