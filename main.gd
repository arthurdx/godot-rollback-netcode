extends Node2D

const DUMMY_NETWORK_ADAPTOR = preload("res://addons/godot-rollback-netcode/DummyNetworkAdaptor.gd")

@export var main_menu: HBoxContainer
@export var connection_panel : Popup
@export var host_field: LineEdit
@export var port_field: LineEdit
@export var message_label: Label
@export var sync_lost_label: Label
@export var server_player: Node2D
@export var client_player: Node2D
@export var reset_button: Button

const LOG_FILE_DIRECTORY = "user://detailed_logs"

var logging_enabled := true

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
	main_menu.visible = false
	message_label.text = "Listening..."


func _on_client_button_pressed() -> void:
	var peer := ENetMultiplayerPeer.new()
	peer.create_client(host_field.text, int(port_field.text))
	multiplayer.multiplayer_peer = peer
	connection_panel.visible = false
	main_menu.visible = false
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
	
	if logging_enabled and not SyncReplay.active:
		var _dir = DirAccess.open(LOG_FILE_DIRECTORY)
		if not DirAccess.dir_exists_absolute(LOG_FILE_DIRECTORY):
			DirAccess.make_dir_absolute(LOG_FILE_DIRECTORY)
		var datetime = Time.get_datetime_dict_from_system()
		var log_file_name = "%04d%02d%02d-%02d%02d%02d-peer-%d.log" % [
			datetime['year'],
			datetime['month'],
			datetime['day'],
			datetime['hour'],
			datetime['minute'],
			datetime['second'],
			multiplayer.get_unique_id(),
		]
		SyncManager.start_logging(LOG_FILE_DIRECTORY + "/" + log_file_name)
		
func _on_SyncManager_sync_stopped() -> void:
	if logging_enabled:
		SyncManager.stop_logging()

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
	
func setup_match_for_replay(my_peer_id: int, peer_ids: Array, \
	match_info: Dictionary) -> void:
		connection_panel.visible = false
		main_menu.visible = false
		reset_button.visible = false


func _on_online_button_pressed():
	connection_panel.popup_centered()
	SyncManager.reset_network_adaptor()


func _on_local_button_pressed():
	main_menu.visible = false
	client_player.input_prefix = "player2_"
	SyncManager.network_adaptor = DUMMY_NETWORK_ADAPTOR.new()
	SyncManager.start()
