extends Node2D

@export var connection_panel : PanelContainer
@export var host_field: LineEdit
@export var port_field: LineEdit
@export var message_label: Label
@export var sync_lost_label: Label
@export var server_player: Node2D
@export var client_player: Node2D

func _ready() -> void:
#	get_tree().connect("network_peer_connected", Callable(self, "_on_network_peer_connected"))
#	get_tree().connect("network_peer_disconnected", Callable(self, "_on_network_peer_disconnected"))
#	get_tree().connect("server_disconnected", Callable(self, "_on_server_disconnected"))
	multiplayer.peer_connected.connect(_on_network_peer_connected)
	multiplayer.peer_disconnected.connect(_on_network_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	SyncManager.connect("sync_started", Callable(self, "_on_SyncManager_sync_started"))
	SyncManager.connect("sync_stopped", Callable(self, "_on_SyncManager_sync_stopped"))
	SyncManager.connect("sync_lost", Callable(self, "_on_SyncManager_sync_lost"))
	SyncManager.connect("sync_regained", Callable(self, "_on_SyncManager_sync_regained"))
	SyncManager.connect("sync_error", Callable(self, "_on_SyncManager_sync_error"))



func _on_server_button_pressed() -> void:
	var peer := ENetMultiplayerPeer.new()
	peer.create_server(int(port_field.text), 1)
	multiplayer.multiplayer_peer = peer
	connection_panel.visible = false
	message_label.text = "Listening..."


func _on_client_button_pressed() -> void:
	var peer := ENetMultiplayerPeer.new()
	peer.create_client(host_field.text, int(port_field.text))
	multiplayer.multiplayer_peer = peer
	connection_panel.visible = false
	message_label.text = "Connecting..."
	
func _on_network_peer_connected(peer_id: int) -> void:
	message_label.text = "Connected!"
	SyncManager.add_peer(peer_id)
	server_player.set_multiplayer_authority(1)
	if multiplayer.is_server():
		client_player.set_multiplayer_authority(peer_id)
		message_label.text = "Starting..."
		await get_tree().create_timer(2.0).timeout
		SyncManager.start()
	else:
		client_player.set_multiplayer_authority(multiplayer.get_unique_id())
	
	
func _on_network_peer_disconnected(peer_id: int) -> void:
	message_label.text = "Disconnected"
	SyncManager.remove_peer(peer_id)
	
func _on_server_disconnected() -> void:
	_on_network_peer_disconnected(1)
	


func _on_reset_button_pressed() -> void:
	SyncManager.stop()
	SyncManager.clear_peers()
	var peer = multiplayer.multiplayer_peer
	if peer:
		peer.close()
	get_tree().reload_current_scene()
	
func _on_SyncManager_sync_started() -> void:
	message_label.text = "Started!"

func _on_SyncManager_sync_stopped() ->void:
	pass

func _on_SyncManager_sync_lost() -> void:
	sync_lost_label.visible = true

func _on_SyncManager_sync_regained() -> void:
	sync_lost_label.visible = false
	
func _on_SyncManager_sync_error(msg: String) -> void:
	sync_lost_label.text = "Fatal sync error: " + msg
	sync_lost_label.visible = false
	var peer = multiplayer.multiplayer_peer
	if peer:
		peer.close()
	SyncManager.clear_peers()
