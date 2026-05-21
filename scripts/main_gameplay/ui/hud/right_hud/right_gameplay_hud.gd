class_name HudRight extends HudParent

#@onready var control: Control = $Control

func _ready() -> void:
	LevelController.gameplay_HUD_right = self;
	
	#get_rockets();

	await get_tree().physics_frame
	
	var cam = LevelController.player_camera
	_hud_prev_basis = cam.global_basis

	await get_tree().process_frame

func _process(delta : float):
	
	_update_hud_drag(delta)

	#set_rocket_bars(LevelController.player.rocket_launcher_component.get_rockets())
