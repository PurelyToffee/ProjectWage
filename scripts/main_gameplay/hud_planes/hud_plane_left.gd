extends HudPlane


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	super._ready();
	
	LevelController.hud_plane_left = self;
	
	pass # Replace with function body.
