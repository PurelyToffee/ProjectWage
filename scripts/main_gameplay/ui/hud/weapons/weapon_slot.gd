class_name WeaponSlot extends GameplayHudElement

@onready var progress_bar_outline: NinePatchRect = %ProgressBarOutline
@onready var sub_viewport_container: SubViewportContainer = $SubViewportContainer

func set_alpha(val : float) -> void:
	sub_viewport_container.modulate.a = val;
