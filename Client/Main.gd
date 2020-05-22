extends Control

onready var status = $MainLobby/VBoxContainer/TopBar/Status
onready var chat = $MainLobby/VBoxContainer/MainBox/CenterBox/HBoxContainer/ChatEdit
onready var chatBox = $MainLobby/VBoxContainer/MainBox/CenterBox/ChatBox
onready var userList = $MainLobby/VBoxContainer/MainBox/RightBox/ScrollContainer/UserList
onready var lobbyList = $MainLobby/VBoxContainer/MainBox/LeftBox/VBoxContainer/ScrollContainer/LobbyList
onready var playerList = $GameLobby/VBoxContainer2/HBoxContainer2/PlayerList
var game = preload("res://Game.tscn")

func _ready():
# warning-ignore:return_value_discarded
	gamestate.connect("failed", self, "_on_failed")
# warning-ignore:return_value_discarded
	gamestate.connect("connected", self, "_on_connected")
# warning-ignore:return_value_discarded
	gamestate.connect("disconnected", self, "_on_disconnected")
# warning-ignore:return_value_discarded
	gamestate.connect("update_lobby_id", self, "_update_lobby_id")
# warning-ignore:return_value_discarded
	gamestate.connect("update_user_list", self, "_update_user_list")
# warning-ignore:return_value_discarded
	gamestate.connect("update_messages", self, "_update_messages")
# warning-ignore:return_value_discarded
	gamestate.connect("update_lobby_list", self, "_update_lobby_list")
# warning-ignore:return_value_discarded
	gamestate.connect("update_player_list", self, "_update_player_list")
	if get_tree().has_network_peer():
		print(get_tree().get_network_unique_id())
		_update_lobby_list()
		_update_user_list()
		status.text = "Connected:" + str(gamestate.my_id)
		status.modulate = Color.green
		$MainLobby.show()

func _on_JoinButton_pressed():
	gamestate.my_name = $LoginScreen/UserName/UserNameLineEdit.text
	gamestate.connect_to_server()

func _on_JoinButton2_pressed():
	gamestate.my_name = $LoginScreen/UserName/UserNameLineEdit.text
	gamestate.ip = "localhost"
	gamestate.connect_to_server()

func _on_SendButton_pressed():
	var message = chat.text
	if message.empty():
		return
	chat.clear()
	var message_data = {"name": gamestate.my_name, "text": message}
	gamestate.send_message(message_data)

func _on_ButtonHost_pressed():
	#let server know that you created a lobby and let it generate a random id
	gamestate.rpc_id(1, "lobby_created")
	$GameLobby.show()
	$GameLobby/VBoxContainer2/HBoxContainer/Start.visible = true
	$GameLobby/VBoxContainer2/HBoxContainer/Ready.visible = false

func _on_ButtonMatch_pressed():
	pass

func _on_connected():
	status.text = "Connected:" + str(gamestate.my_id)
	status.modulate = Color.green
	
	$MainLobby.show()

func _on_failed():
	status.text = "Connection Failed, trying again"
	status.modulate = Color.red
	
	$MainLobby.hide()
	$GameLobby.hide()

func _on_disconnected():
	status.text = "Server Disconnected, trying to connect..."
	status.modulate = Color.red
	
	$MainLobby.hide()
	$GameLobby.hide()

# update lists
func _update_user_list():
	userList.clear()
	for user in gamestate.get_user_list():
		userList.add_item(str(user.name), null, true)
		
func _update_lobby_id(lobby_id):
	$GameLobby/VBoxContainer2/LobbyName.text = lobby_id
	
func _update_messages(message_data):
	var message = message_data["name"] + ": " + message_data["text"]
	chatBox.text += message+"\n"

func _update_lobby_list():
	lobbyList.clear()
	for lobby in gamestate.lobbies:
		lobbyList.add_item(str(lobby), null, false)

func _update_player_list():
	playerList.clear()
	for player_id in gamestate.lobbies[gamestate.my_lobby_id].players:
		var player_name = gamestate.lobbies[gamestate.my_lobby_id].players[player_id].name
		playerList.add_item(player_name, null, true)
	
func _on_LobbyList_item_activated(index):
	var lobby_id = lobbyList.get_item_text(index)
	gamestate.rpc_id(1, "lobby_joined", lobby_id)
	$GameLobby.show()
	
func _on_ClientUI_closed():
	$GameLobby.hide()


func _on_Close_pressed():
	gamestate.rpc_id(1, "lobby_left", gamestate.my_lobby_id)
	gamestate.my_lobby_id = ""
	$GameLobby.hide()



func _on_Start_pressed():
	gamestate.rpc_id(1, "start_game", gamestate.my_lobby_id)


func _on_Ready_pressed():
	pass # Replace with function body.
