extends Node3D

@onready var sub_viewport_container: SubViewportContainer = %SubViewportContainer

func _on_ready() -> void:
	LevelController.current_level = self;


func reset_level() -> Node3D:
	var parent = self.get_parent()
	var scene_path = self.scene_file_path
	
	self.queue_free()
	
	var new_level = load(scene_path).instantiate()
	parent.add_child(new_level)
	
	
	return new_level;
