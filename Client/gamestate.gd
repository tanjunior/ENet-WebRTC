extends Node

# Game port and ip
#const ip = "34.87.101.65"
var ip = "35.187.242.182"
const DEFAULT_PORT = 44444

# Signal to let GUI know whats up
signal failed
signal connected
signal disconnected
signal update_secret(secret)
signal update_messages(message_data)
signal update_user_list
signal update_lobby_list
signal update_player_list

var is_host = false
remote var my_secret setget set_secret
remote var my_name = "Client"
var my_id
# User dict stored as id:name
remote var users : Dictionary = {} setget set_users
# Lobbies dict stored as id:{users}
remote var lobbies: Dictionary = {} setget set_lobbies
remote var players: Dictionary = {}

func _ready():
# warning-ignore:return_value_discarded
	get_tree().connect("connected_to_server", self, "_on_connected_to_server")
# warning-ignore:return_value_discarded
	get_tree().connect("connection_failed", self, "_on_connection_failed", [], CONNECT_DEFERRED)
# warning-ignore:return_value_discarded
	get_tree().connect("server_disconnected", self, "_on_server_disconnected")

# Callback from SceneTree, called when connect to server
func _on_connected_to_server():
	emit_signal("connected")
	# Register ourselves with the server
	rpc_id(1, "register_user", my_name)
	my_id = get_tree().get_network_unique_id()


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

remote func lobby_created(secret, lobby):
	self.lobbies[secret] = lobby
	print("lobby_created")

remote func lobby_updated(state, id, new_player_data = null):
	if state == "join":
		self.lobbies[my_secret].players[id] = new_player_data
	if state == "left":
		self.lobbies[my_secret].players.erase(id)
	emit_signal("update_player_list")

func set_lobbies(value):
	lobbies = value
	print("received lobbies")
	emit_signal("update_lobby_list")
	
func set_users(value):
	users = value
	print("received users")
	emit_signal("update_user_list")

func set_secret(value):
	my_secret = value
	emit_signal("update_secret", my_secret)

remote func init_rtc():
	webrtc.init_rtc()
