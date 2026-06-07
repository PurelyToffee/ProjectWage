class_name EnemyRespawner extends Node

var respawn_time: float
var timer: Timer = Timer.new()
var enemy_parent: Node3D
var enemy_scene: PackedScene
var respawn_pos: Vector3 #TODO: apply Transform3D if it becomes relevant
var dead_enemy: ParentEnemy

func _init(enemy: ParentEnemy, respawn_time_: float) -> void:
	self.dead_enemy = enemy
	enemy_parent = enemy.get_parent()
	enemy_scene = load(enemy.scene_file_path)
	self.respawn_time = respawn_time_
	self.respawn_pos = enemy.respawn_pos
	self.add_child(timer) # use parent because child may disappear before timeout (e.g. floater)
	enemy_parent.add_child(self)
	timer.start(respawn_time)
	timer.timeout.connect(_respawn)

func _respawn() -> void:
	var newEnemy = enemy_scene.instantiate()
	enemy_parent.add_child(newEnemy)
	newEnemy.position = respawn_pos
	newEnemy.respawn_pos = respawn_pos
	if is_instance_valid(dead_enemy):
		dead_enemy.queue_free()
	self.queue_free()
