class_name MainGameplay extends Node3D

@onready var gameplay_viewport: SubViewport = %GameplayViewport

func _on_ready() -> void:
	
	LevelController.gameplay_node = self;
	LevelController.close_menu() # some bs to make sure the LevelController state is correct
	
	%GameplayHUD.viewport_scale = %GameplayViewportContainer.stretch_shrink;
	pass


func set_level(level : PackedScene) -> void:
	
	var l = level.instantiate()
	
	await ready
	gameplay_viewport.add_child(l);
