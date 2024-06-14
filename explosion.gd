extends Node2D

@export var despawn_timer: NetworkTimer
@export var animation_player: NetworkAnimationPlayer

func _network_spawn(data: Dictionary) -> void:
	global_position = data['position']
	despawn_timer.start()
	animation_player.play("Explode")
	
func _network_despawn() -> void:
	pass

func _on_despawn_timer_timeout():
	SyncManager.despawn(self)
