extends Node

var deltaMultiplier : float = 0.;


func _process(delta : float) -> void:
	deltaMultiplier = 60. / (1./delta);
