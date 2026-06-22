class_name ViewmodelManager extends Control

@onready var telekinesis_viewmodel: Viewmodel = %telekinesis_viewmodel
@onready var wage_kick_viewmodel: Viewmodel = %wage_kick_viewmodel


func _ready() -> void:
	LevelController.viewmodel_manager = self;


func play_telekinesis() -> void:
	telekinesis_viewmodel.play_animation();

func play_kick() -> void:
	wage_kick_viewmodel.play_animation();
