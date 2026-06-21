extends Resource
class_name TutorialPageData

# exported variables must have fixed types -> can't mix video/image
#@export var media = preload("res://textures/tutorials/demoman.ogv");

# not using UID because godot couldn't find the UID
@export var image: Texture2D #= preload("uid://rciv11ad8drm");
@export var video: VideoStream #= preload("res://textures/tutorials/demoman.ogv");
@export var title: String = "Tutorial Placeholder Title"
@export_multiline var description: String = "If you're reading this.\nYou shouldn't."

@export_group("Input Gate")
## Ordered steps the player must perform before this page's advance button
## (Next, or Done on the last page) unlocks. Each step is one or more InputMap
## action names that must be pressed together, joined with "+".
## Examples: "jump"  |  "dash"  |  "jump+crouch".
## Steps must be performed in order. Leave empty for no gate.
@export var required_input_steps: Array[String] = []
## How many times the full step sequence must be completed.
@export var required_input_repeats: int = 1
