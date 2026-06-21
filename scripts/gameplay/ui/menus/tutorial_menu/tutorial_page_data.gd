extends Resource
class_name TutorialPageData

#@export var image: Texture2D = preload("uid://rciv11ad8drm");

# not using UID because godot couldn't find the UID
@export var video: VideoStream = preload("res://textures/tutorials/demoman.ogv");
@export var title: String = "Tutorial Placeholder Title"
@export_multiline var description: String = "If you're reading this.\nYou shouldn't."
