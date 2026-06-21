extends Resource
class_name TutorialPageData

# exported variables must have fixed types -> can't mix video/image
#@export var media = preload("res://textures/tutorials/demoman.ogv");

# not using UID because godot couldn't find the UID
@export var image: Texture2D #= preload("uid://rciv11ad8drm");
@export var video: VideoStream #= preload("res://textures/tutorials/demoman.ogv");
@export var title: String = "Tutorial Placeholder Title"
@export_multiline var description: String = "If you're reading this.\nYou shouldn't."
