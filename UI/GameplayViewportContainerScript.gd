extends SubViewportContainer

@onready var gameplay_viewport: SubViewport = %GameplayViewport


func _on_ready() -> void:
	gameplay_viewport.size = get_viewport().size;
	LevelController.gameplay_viewport_container = self;
	pass # Replace with function body.
