extends Node2D

@export var despawn_timer: NetworkTimer

func _network_spawn(data: Dictionary) -> void:
	global_position = data['position']
	despawn_timer.start()




func _on_despawn_timer_timeout():
	SyncManager.despawn(self)
