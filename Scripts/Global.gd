extends Node

var deltaMultiplier : float = 0.;

var player : CharacterBody3D;
var player_attack_origin : Node3D;
var player_camera : Camera3D;

var hud : CanvasLayer;

const DualMacTen := preload("res://scripts/weapons/Arsenal/DualMacTenWeapon.gd")


func _process(delta : float) -> void:
	deltaMultiplier = 60. / (1./delta);


func player_is_crouched() -> bool:
	return player.is_crouched;
