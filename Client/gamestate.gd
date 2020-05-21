extends Node

# Game port and ip
#const ip = "34.87.101.65"
var ip = "35.187.242.182"
const DEFAULT_PORT = 44444

# Signal to let GUI know whats up
signal failed
signal connected
signal disconnected
signal update_lobby_id(lobby_id)
signal update_messages(message_data)
signal update_user_list
signal update_lobby_list
signal update_player_list
signal rtc_handshake(caller_id, data)


#var game = preload("res://Game.tscn")
var is_host = false
remote var my_lobby_id setget set_lobby_id
remote var my_name = "Client"
var my_peer_id
var my_id
# User dict stored as id:name
remote var users : Dictionary = {} setget set_users
# Lobbies dict stored as id:{users}
remote var lobbies: Dictionary = {} setget set_lobbies
remote var players: Dictionary = {} setget set_players

func _ready():
# warning-ignore:return_value_discarded
	get_tree().connect("connected_to_server", self, "_on_connected_to_server")
# warning-ignore:return_value_discarded
	get_tree().connect("connection_failed", self, "_on_connection_failed", [], CONNECT_DEFERRED)
# warning-ignore:return_value_discarded
	get_tree().connect("server_disconnected", self, "_on_server_disconnected")

# Callback from SceneTree, called when connect to server
func _on_connected_to_server():
	my_id = get_tree().get_network_unique_id()
	emit_signal("connected")
	# Register ourselves with the server
	rpc_id(1, "register_user", my_name)


# Callback from SceneTree, called when server disconnect
func _on_server_disconnected():
	users.clear()
	emit_signal("disconnected")
	
	# Try to connect again
	var err = connect_to_server()
	if !err:
		get_tree().set_network_peer(null)


# Callback from SceneTree, called when unabled to connect to server
func _on_connection_failed():
	get_tree().set_network_peer(null) # Remove peer
	emit_signal("failed")
	
	# Try to connect again
	var err = connect_to_server()
	if !err:
		get_tree().set_network_peer(null)

func connect_to_server():
	var peer = NetworkedMultiplayerENet.new()
	var err = peer.create_client(ip, DEFAULT_PORT)
	if err == OK:
		get_tree().set_network_peer(peer)
		return true
	elif err == ERR_ALREADY_IN_USE:
		peer.close_connection()
		connect_to_server()
		return
	return false
	
remote func change_name(name):
	my_name = name
	
remote func user_connected(id, new_user_data):
	self.users[id] = new_user_data

remote func user_disconnected(id):
	self.users.erase(id)


# Returns list of player names
func get_user_list():
	return users.values()

func get_lobby_list():
	return lobbies.values()


func send_message(message_data):
	rpc("add_message", message_data)
	
remotesync func add_message(message_data):
	emit_signal("update_messages", message_data)

remote func lobby_created(lobby_id, lobby):
	self.lobbies[lobby_id] = lobby
	print("lobby_created")

remote func lobby_updated(state, id, new_player_data = null):
	if state == "join":
		self.lobbies[my_lobby_id].players[id] = new_player_data
	if state == "left":
		self.lobbies[my_lobby_id].players.erase(id)
	emit_signal("update_player_list")

func set_lobbies(value):
	lobbies = value
	print("received lobbies")
	emit_signal("update_lobby_list")
	
func set_users(value):
	users = value
	print("received users")
	emit_signal("update_user_list")
	
func set_players(value):
	players = value
	my_peer_id = players[my_id].peer_id
	print("Received players")
	
func set_lobby_id(value):
	my_lobby_id = value
	emit_signal("update_lobby_id", my_lobby_id)

remote func init_game():
#	get_tree().change_scene_to(game)
	get_tree().change_scene("res://Game.tscn")
#	webrtc.init_rtc()

remote func rtc_handshake(data):
	var caller_id = get_tree().get_rpc_sender_id()
	emit_signal("rtc_handshake", caller_id, data)
