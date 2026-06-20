extends GPUParticles3D

@export var node : Node3D;

func _ready() -> void:
	process_priority = 1;
	global_position = node.global_position;

func _process(delta: float) -> void:
	global_position = node.global_position;
