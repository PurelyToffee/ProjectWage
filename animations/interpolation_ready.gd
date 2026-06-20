class_name AnimationPlayerParent extends AnimationPlayer

@export var interpolation_mode : int = 0;

func _ready() -> void:
	var tracks = get_animation_list();
	
	for t in tracks:
		var anim_track_1 = get_animation(t) # get the Animation that you are interested in (change "default" to your Animation's name)
		var count  = anim_track_1.get_track_count() # get number of tracks (bones in your case)
		for i in count:
			
			anim_track_1.track_set_interpolation_type(i, interpolation_mode) # change interpolation mode for every track
			print(anim_track_1.track_get_interpolation_type(i))
