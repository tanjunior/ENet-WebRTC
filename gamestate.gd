extends Node

# Default game port
const DEFAULT_PORT = 44444

# Max number of players
const MAX_PLAYERS = 4095

# Players dict stored as id:name
var users : Dictionary = {}
var lobbies : Dictionary = {}

const ALFNUM = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
var _alfnum = ALFNUM.to_ascii()
var rand: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready():
# warning-ignore:return_value_discarded
	get_tree().connect("network_peer_connected", self, "_user_connected")
# warning-ignore:return_value_discarded
	get_tree().connect("network_peer_disconnected", self,"_user_disconnected")
	create_server()


func create_server():
	
	var host = NetworkedMultiplayerENet.new()
	var err = host.create_server(DEFAULT_PORT, MAX_PLAYERS)
	if err == OK:
		print("Server started succesfully")
		get_tree().set_network_peer(host)
	elif err == ERR_ALREADY_IN_USE:
		print("Already has an open connection")
		yield(host.close_connection(), "completed")
		create_server()
	elif err == ERR_CANT_CREATE:
		print("Can't create server")


# Callback from SceneTree, called when client connects
func _user_connected(_id):
	print("Client ", _id, " connected")


# Callback from SceneTree, called when client disconnects
func _user_disconnected(id):
	print("Client ", id, " disconnected")
	rpc("user_disconnected", id)
	var lobb
	if users[id].has("lobby_id"):
		var lobby_id = users[id].lobby_id
		print("this user has key:lobby_id, value:%s" %lobby_id)
		lobbies[lobby_id].players.erase(id)
		if lobbies[lobby_id].players.size() == 0:
			lobbies.erase(lobby_id)
			rset("lobbies", lobbies)
	users.erase(id)


# Player management functions
remote func register_user(user_name):
	# We get id this way instead of as parameter, to prevent users from pretending to be other users
	var caller_id = get_tree().get_rpc_sender_id()

	# Add number increment to name if duplicate
	var names:Array = []
	var i = 1
	for user_id in users:
		names.append(users[user_id].name) 
	while names.has(user_name):
		var new_user_name = user_name + str(i)
		i = i + 1
		if !names.has(new_user_name):
			user_name = new_user_name

	rset_id(caller_id, "my_name", user_name)
	
	# Add him to our list
	users[caller_id] = {"name":user_name}
	# Send user and lobby list to new player
	rset_id(caller_id, "users", users)
	rset_id(caller_id, "lobbies", lobbies)
	
	# Send new dude to all players
	for user_id in users:
		if user_id == caller_id:
			continue
		rpc_id(user_id, "user_connected", caller_id, users[caller_id])

	print("Client ", caller_id, " registered as ", user_name)

remotesync func add_message(_message_data):
	pass

remote func lobby_created():
	var lobby : Dictionary = {}
	var caller_id = get_tree().get_rpc_sender_id()
	var lobby_id = ""
	for _i in range(0, 32):
		lobby_id += char(_alfnum[rand.randi_range(0, ALFNUM.length()-1)])
	rset_id(caller_id, "my_lobby_id", lobby_id)
	var player = {caller_id:{"name":users[caller_id].name}}
	lobby["host"] = caller_id
	lobby["players"] = player
	lobbies[lobby_id] = lobby
	users[caller_id]["lobby_id"] = lobby_id
	#update all users of new lobby
	print("User: %s created a lobby %s" %[users[caller_id].name, lobby_id])
	rpc("lobby_created", lobby_id, lobbies[lobby_id], caller_id)

remote func lobby_joined(lobby_id):
	var caller_id = get_tree().get_rpc_sender_id()
	rset_id(caller_id, "my_lobby_id", lobby_id)
	
	#add new player in to lobby player list
	var new_player_data = {"name":users[caller_id].name}
	users[caller_id]["lobby_id"] = lobby_id
	lobbies[lobby_id].players[caller_id] = new_player_data

	rpc("lobby_updated", "join", lobby_id, caller_id, new_player_data)

remote func lobby_left(lobby_id):
	var caller_id = get_tree().get_rpc_sender_id()
	
	users[caller_id].erase("lobby_id")
	lobbies[lobby_id].players.erase(caller_id)
	if lobbies[lobby_id].players.size() == 0:
		lobbies.erase(lobby_id)
		rset("lobbies", lobbies)
	else:
		rpc("lobby_updated", "left", lobby_id, caller_id, null)
	
remote func start_game(lobby_id):
	var caller_id = get_tree().get_rpc_sender_id()
	var next_peer_id = 2
	var game = { "players" : {}}
	for user_id in lobbies[lobby_id].players:
		var player_data = lobbies[lobby_id].players[user_id]
		
		game.players[user_id] = player_data
		if user_id == caller_id:
			game.players[user_id].peer_id = 1
			continue
		game.players[user_id].peer_id = next_peer_id
		next_peer_id += 1
		
	for user_id in game.players:
		rset_id(user_id, "players", game.players)
#		rpc_id(user_id, "init_game")

#	for user_id in game.players:
#		rpc_id(user_id, "init_game")

	
remote func get_lobbies():
	var caller_id = get_tree().get_rpc_sender_id()
	rset_id(caller_id, "lobbies", lobbies)
