class_name BlasterShot extends ProjectileParent

@export var blaster_enemy_explosion : PackedScene;
@export var blaster_friendly_explosion : PackedScene;

func damage_default(body) -> void:
	var explosion = LevelController.create_scene(blaster_friendly_explosion)
	explosion.global_transform = global_transform;
	
	
func damage_player(skip : bool = false) -> void:
	
	if !skip and parryable:
		grace_period = parryable_grace_period;
		grace = true;
		print("parrying start")
		return;
	
	var explosion = LevelController.create_scene(blaster_enemy_explosion)
	explosion.global_transform = global_transform;
	
func _on_area_3d_body_entered(body: Node) -> void:
	
	if body.is_in_group(damage_target):
		
		match(damage_target):
			
			"player": 
				damage_player()
				if grace : return;
			
			"_": 
				if body is BlasterEnemy: return;
				damage_default(body);
				queue_free()
