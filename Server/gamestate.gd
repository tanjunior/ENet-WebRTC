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
	rpc("user_disconnected", id)
	users.erase(id)
	print("Client ", id, " disconnected")


# Player management functions
remote func register_user(user_name):
	# We get id this way instead of as parameter, to prevent users from pretending to be other users
	var caller_id = get_tree().get_rpc_sender_id()

	# Add number increment to name if duplicate
	var names = users.values()
	var i = 1
	while names.has(user_name):
		var new_user_name = user_name + str(i)
		i = i + 1
		if !names.has(new_user_name):
			user_name = new_user_name

	rset_id(caller_id, "my_name", user_name)
	
	# Add him to our list
	users[caller_id] = user_name
	# Send user and lobby list to new player
	rset_id(caller_id, "users", users)
	rset_id(caller_id, "lobbies", lobbies)
	
	# Send new dude to all players
	for p_id in users:
		if p_id == caller_id:
			continue
		rpc_id(p_id, "user_connected", caller_id, users[caller_id])

	print("Client ", caller_id, " registered as ", user_name)

remotesync func add_message(_message_data):
	pass

remote func lobby_created():
	var lobby : Dictionary = {}
	var caller_id = get_tree().get_rpc_sender_id()
	var secret = ""
	for _i in range(0, 32):
		secret += char(_alfnum[rand.randi_range(0, ALFNUM.length()-1)])
	rset_id(caller_id, "my_secret", secret)
	var player = {caller_id:{"name":users[caller_id]}}
	lobby["host"] = users[caller_id]
	lobby["players"] = player
	lobbies[secret] = lobby

	print(lobbies[secret])
	#update all users of new lobby
	print("User: %s created a lobby %s" %[users[caller_id], secret])
	rpc("lobby_created", secret, lobbies[secret])

remote func lobby_joined(secret):
	var caller_id = get_tree().get_rpc_sender_id()
	rset_id(caller_id, "my_secret", secret)
	
	#add new player in to lobby player list
	var new_player_data = {"name":users[caller_id]}
	lobbies[secret].players[caller_id] = new_player_data

	rpc("lobby_updated", "join", caller_id, new_player_data)

remote func lobby_left(secret):
	var caller_id = get_tree().get_rpc_sender_id()
	
	lobbies[secret].players.erase(caller_id)
	if lobbies[secret].players.size() == 0:
		lobbies.erase(secret)
		rset("lobbies", lobbies)
	else:
		rpc("lobby_updated", "left", caller_id)
	
remote func start_game(secret):
	var caller_id = get_tree().get_rpc_sender_id()
	var next_peer_id = 2
	var game = { "players" : {}}
	for user_id in lobbies[secret].players:
		var player_data = lobbies[secret].players[user_id]
		
		game.players[user_id] = player_data
		if user_id == caller_id:
			game.players[user_id].peer_id = 1
			continue
		game.players[user_id].peer_id = next_peer_id
		next_peer_id += 1
	for p in game.players:
		rset_id(p, "players", game.players)

	for p in game.players:
		rpc_id(p, "init_rtc")
	
remote func get_lobbies():
	var caller_id = get_tree().get_rpc_sender_id()
	rset_id(caller_id, "lobbies", lobbies)
