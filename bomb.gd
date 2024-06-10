extends Node2D

@export var explosion_timer: NetworkTimer
const explosion = preload("res://explosion.tscn")

#func _network_spawn_preprocess(data: Dictionary) -> Dictionary:
#	data["player_path"] = data['player'].get_path()
#	data.erase('player')
#	return data

func _network_spawn(data: Dictionary) -> void:
	global_position = data['position']
	explosion_timer.start()
	

func _on_explosion_timer_timeout():
	SyncManager.spawn("explosion", get_parent(), explosion, {
		position = global_position,
	})
	SyncManager.despawn(self)
