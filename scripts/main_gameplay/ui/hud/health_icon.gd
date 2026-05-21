class_name HealthIcon extends TextureRect

@export var textures : Array[Texture];

func set_sprite(index : int) -> void:
	self.texture = textures[index];
