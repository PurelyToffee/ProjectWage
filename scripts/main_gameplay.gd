extends Node3D

@onready var gameplay_viewport: SubViewport = %GameplayViewport

func _on_ready() -> void:
	%GameplayHUD.viewport_scale = %GameplayViewportContainer.stretch_shrink;
	pass


func set_level(level : PackedScene) -> void:
	
	var l = level.instantiate()
	
	await ready
	gameplay_viewport.add_child(l);
