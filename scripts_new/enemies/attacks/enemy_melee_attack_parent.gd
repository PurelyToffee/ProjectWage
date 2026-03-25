extends Area3D

@export var damage := 30.;
@export var max_parry_time := 0.15;
@export var knockback_force := 12.0;
@export var knockback_vertical_bonus := 4;

var parry_time : float;
var creator : CharacterBody3D;


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	parry_time = max_parry_time;
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	parry_time = maxf(parry_time - delta, 0.)
	
	if parry_time == 0:
		deal_damage()
		queue_free()
	
	pass

func set_creator(object : CharacterBody3D) -> void:
	creator = object;

func parry() -> void:
	creator.parry();
	queue_free()

func deal_damage() -> void:
	
	for body in self.get_overlapping_bodies():
		if !body.is_in_group("player") : continue;
		
		body.health_component.take_damage(damage)
		var knockback_dir =  global_position.direction_to(body.global_position) 
		knockback_dir.y = 0;

		MovementUtils.apply_knockback(body, knockback_dir, knockback_force, knockback_vertical_bonus, true)
		GameJuice.shake_camera(0.6, 0.3)
		break;
