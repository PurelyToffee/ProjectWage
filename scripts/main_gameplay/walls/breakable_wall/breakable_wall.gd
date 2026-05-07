class_name BreakableWall extends CustomCharacterBody

@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	
	health_component.setup(health, false);
	health_component.connect("died", on_died)

func on_died() -> void:
	queue_free();
