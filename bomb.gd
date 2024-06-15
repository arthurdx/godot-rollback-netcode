extends Node2D

@export var explosion_timer: NetworkTimer
@export var animation_player: NetworkAnimationPlayer
const EXPLOSION = preload("res://explosion.tscn")

#func _network_spawn_preprocess(data: Dictionary) -> Dictionary:
#	data["player_path"] = data['player'].get_path()
#	data.erase('player')
#	return data

func _network_spawn(data: Dictionary) -> void:
	global_position = data['position']
	explosion_timer.start()
	animation_player.play("Tick")
	

func _network_despawn() -> void:
	pass
	

func _on_explosion_timer_timeout():
	SyncManager.spawn("Explosion", get_parent(), EXPLOSION, {
		position = global_position,
	})
	SyncManager.despawn(self)
