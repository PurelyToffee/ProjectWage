extends Area3D

@export var damage := 30.;
@export var max_parry_time := 0.5;

var parry_time : float;
var creator : CharacterBody3D;


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	parry_time = max_parry_time;
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	parry_time = maxf(parry_time - delta, 0.)
	print(parry_time)
	
	if parry_time == 0:
		deal_damage()
		queue_free()
	
	pass

func set_creator(object : CharacterBody3D) -> void:
	creator = object;


func parry() -> void:
	creator.health_component.take_damage(100);
	LevelController.power_kick();
	queue_free()

func deal_damage() -> void:
	
	for body in self.get_overlapping_bodies():
		if !body.is_in_group("player") : continue;
		
		body.health_component.take_damage(damage)
		
		break;
