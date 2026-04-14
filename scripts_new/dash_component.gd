class_name DashComponent extends Node

@export var dash_speed := 15.0

@export var dash_jump_velocity := 8.0

@export var dash_max_count := 2.0;
@export var dash_recovery_spd := 0.5;

@export var max_dash_duration := 0.3;
var dash_duration := 0.0;

var holder : CharacterBody3D = null;
var dash_count : float;

signal stop_dashing();

func _ready() -> void:
	dash_count = dash_max_count


func _process(delta: float) -> void:
	
	dash_count = clampf(dash_count + delta * dash_recovery_spd, 0.0,  dash_max_count);
	dash_duration = maxf(dash_duration - delta, 0.0);

	if dash_duration == 0.0:
		stop_dashing.emit();


func change_dash_dir(dir : Vector3) -> void:

	if dash_duration == 0. : return;

	dir = dir.normalized();
	var spd = holder.velocity.length();
	holder.velocity = dir * (maxf(spd, dash_speed));
	
	print(holder.velocity)

func dash(dir : Vector3) -> void:
	
	if dash_count < 1.0: return;
	
	dir = dir.normalized();
	
	
	var spd = holder.velocity.length();
	holder.velocity = dir * (maxf(spd, dash_speed));
	
	dash_count -= 1.0 * int(!MovementUtils.really_on_floor(holder));
	dash_duration = max_dash_duration;
	
	pass;
	
