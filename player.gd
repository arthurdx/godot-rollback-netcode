extends Node2D

const bomb = preload("res://bomb.tscn")

func _ready():
	SyncManager.connect("scene_spawned", Callable(self, "_on_SyncManager_scene_spawned"))
	SyncManager.connect("scene_despawned", Callable(self, "_on_SyncManager_scene_despawned"))

func _get_local_input() -> Dictionary:
	var input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var input := {}
	if input_vector != Vector2.ZERO:
		input["input_vector"] = input_vector
	if Input.is_action_just_pressed("ui_accept"):
		input["drop_bomb"] = true
		
	return input


func _predict_remote_input(previous_input: Dictionary, ticks_since_real_input: int) -> Dictionary:
	var input = previous_input.duplicate()
	input.erase("drop_bomb")
	return input

func _network_process(input: Dictionary) -> void:
	position += input.get("input_vector", Vector2.ZERO) * 8 #Não determinismo devido a conta de 
	#ponto flutuante, corrigir 
	
	if input.get("drop_bomb", false):
		SyncManager.spawn("bomb", get_parent(), bomb, { position = global_position})

func _on_SyncManager_scene_spawned(name: String, spawned_node: Node2D, scene: Node2D, data: Dictionary) -> void:
	if name == "bomb":
		spawned_node.connect("exploded", Callable(self, "_on_bomb_exploded"))
		
func _on_SyncManager_scene_despawned(name: String, despawned_node: Node2D) -> void:
	if name == "bomb":
		despawned_node.disconnect("exploded", Callable(self, "_on_bomb_exploded"))

func _save_state() -> Dictionary:
	return {
		position = position,
	}
	
func _load_state(state: Dictionary) -> void:
	position = state['position']
	
