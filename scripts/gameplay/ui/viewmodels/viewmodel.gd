class_name Viewmodel extends Node3D

@onready var animation_player: AnimationPlayerParent = %AnimationPlayer
@export var animation : String = "rig_001Action";
@export var starting_frame : int = 0;


func play_animation() -> void:
	show();
	animation_player.play(animation);
	animation_player.seek(float(starting_frame)/24.)
	
	await animation_player.animation_finished;
	hide();

func hide_animation() -> void:
	hide();
	animation_player.stop();
