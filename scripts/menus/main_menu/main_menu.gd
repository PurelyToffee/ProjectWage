extends Control

@onready var levels_container: CenterContainer = %LevelsCenterContainer


func _on_play_pressed() -> void:
	
	levels_container.show();
	
	pass # Replace with function body.

func _on_settings_pressed() -> void:
	pass # Replace with function body.

func _on_quit_pressed() -> void:
	get_tree().quit();

func _on_tutorial_pressed() -> void:
	MenuController.play_tutorial();
	
	MenuController.quit()
	
	pass;

func _on_level_1_pressed() -> void:
	pass # Replace with function body.

func _on_level_2_pressed() -> void:
	pass # Replace with function body.
