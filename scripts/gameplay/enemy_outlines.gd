extends SubViewport

func _ready() -> void:
	OutlineManager.mask_viewport = self;
