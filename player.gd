extends Node2D

const BOMB = preload("res://bomb.tscn")

@export var rng: NetworkRandomNumberGenerator

var input_prefix := "player1_"
var speed := 0.0
var teleporting := false

#use if built in pooling is disabled

#func _ready():
#	SyncManager.connect("scene_spawned", Callable(self, "_on_SyncManager_scene_spawned"))
#	SyncManager.connect("scene_despawned", Callable(self, "_on_SyncManager_scene_despawned"))

func _get_local_input() -> Dictionary:
	var input_vector = Input.get_vector(input_prefix + "left",input_prefix + "right", \
		 input_prefix + "up", input_prefix + "down")
	var input := {}
	if input_vector != Vector2.ZERO:
		input["input_vector"] = input_vector
	if Input.is_action_just_pressed(input_prefix + "bomb"):
		input["drop_bomb"] = true
	if Input.is_action_just_pressed(input_prefix + "teleport"):
		input["teleport"] =  true
		
	return input


func _predict_remote_input(previous_input: Dictionary, ticks_since_real_input: int) -> Dictionary:
	var input = previous_input.duplicate()
	input.erase("drop_bomb")
	if ticks_since_real_input > 2:
		input.erase("input_vector")
	return input

func _network_process(input: Dictionary) -> void:
	#Não determinismo devido a conta de ponto flutuante, corrigir 
	var input_vector = input.get("input_vector", Vector2.ZERO)
	if input_vector != Vector2.ZERO:
		if speed < 16.0:
			speed += 1.0
		position += input_vector * speed
	else: 
		speed = 0.0
	
	if input.get("drop_bomb", false):
		SyncManager.spawn("Bomb", get_parent(), BOMB, { position = global_position })
		
	if input.get("teleport", false):
		position = Vector2(rng.randi() % 1024, rng.randi() % 600)
		teleporting = true
	else:
		teleporting = false

#use if built in pooling is disabled

#func _on_SyncManager_scene_spawned(name, spawned_node, scene, data) -> void:
#	if name == "Bomb":
#		spawned_node.connect("exploded", Callable(self, "_on_bomb_exploded"))
#
#func _on_SyncManager_scene_despawned(name,  despawned_node) -> void:
#	if name == "Bomb":
#		despawned_node.disconnect("exploded", Callable(self, "_on_bomb_exploded"))

func _save_state() -> Dictionary:
	return {
		position = position,
		speed = speed,
		teleporting = teleporting,
	}
	
func _load_state(state: Dictionary) -> void:
	position = state['position']
	speed = state['speed']
	teleporting = state['teleporting']
	
func _interpolate_state(old_state: Dictionary, new_state: Dictionary, weight: float) -> void:
	if old_state.get('teleporting', false) or new_state.get('teleporting', false):
		return
	position = lerp(old_state['position'], new_state['position'], weight)
	
