extends Control

onready var status = $Panel/VBoxContainer/TopBar/Status
onready var chat = $Panel/VBoxContainer/MainBox/CenterBox/HBoxContainer/ChatEdit
onready var chatBox = $Panel/VBoxContainer/MainBox/CenterBox/ChatBox
onready var userList = $Panel/VBoxContainer/MainBox/RightBox/ScrollContainer/UserList
onready var lobbyList = $Panel/VBoxContainer/MainBox/LeftBox/VBoxContainer/ScrollContainer/LobbyList
onready var playerList = $Panel2/VBoxContainer2/HBoxContainer2/PlayerList


func _ready():
# warning-ignore:return_value_discarded
	gamestate.connect("failed", self, "_on_failed")
# warning-ignore:return_value_discarded
	gamestate.connect("connected", self, "_on_connected")
# warning-ignore:return_value_discarded
	gamestate.connect("disconnected", self, "_on_disconnected")
# warning-ignore:return_value_discarded
	gamestate.connect("update_secret", self, "_update_secret")
# warning-ignore:return_value_discarded
	gamestate.connect("update_user_list", self, "_update_user_list")
# warning-ignore:return_value_discarded
	gamestate.connect("update_messages", self, "_update_messages")
# warning-ignore:return_value_discarded
	gamestate.connect("update_lobby_list", self, "_update_lobby_list")
# warning-ignore:return_value_discarded
	gamestate.connect("update_player_list", self, "_update_player_list")

func _on_JoinButton_pressed():
	gamestate.my_name = $VBox/HBox/LineEdit.text
	gamestate.connect_to_server()

func _on_JoinButton2_pressed():
	gamestate.my_name = $VBox/HBox/LineEdit.text
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
	$Panel2.show()
	$Panel2/VBoxContainer2/HBoxContainer/Start.visible = true
	$Panel2/VBoxContainer2/HBoxContainer/Ready.visible = false

func _on_ButtonMatch_pressed():
	pass

func _on_connected():
	status.text = "Connected:" + str(gamestate.my_id)
	status.modulate = Color.green
	
	$Panel.show()

func _on_failed():
	status.text = "Connection Failed, trying again"
	status.modulate = Color.red
	
	$Panel.hide()
	$Panel2.hide()

func _on_disconnected():
	status.text = "Server Disconnected, trying to connect..."
	status.modulate = Color.red
	
	$Panel.hide()
	$Panel2.hide()

# update lists
func _update_user_list():
	userList.clear()
	for user in gamestate.get_user_list():
		userList.add_item(str(user), null, true)
		
func _update_secret(secret):
	$Panel2/VBoxContainer2/LobbyName.text = secret
	
func _update_messages(message_data):
	var message = message_data["name"] + ": " + message_data["text"]
	chatBox.text += message+"\n"

func _update_lobby_list():
	lobbyList.clear()
	for lobby in gamestate.lobbies:
		lobbyList.add_item(str(lobby), null, false)

func _update_player_list():
	for player_id in gamestate.lobbies[gamestate.my_secret].players:
		var player_name = gamestate.lobbies[gamestate.my_secret].players[player_id].name
		playerList.add_item(player_name, null, true)
	
func _on_LobbyList_item_activated(index):
	var secret = lobbyList.get_item_text(index)
	gamestate.rpc_id(1, "lobby_joined", secret)
	$Panel2.show()
	
func _on_ClientUI_closed():
	$Panel2.hide()


func _on_Close_pressed():
	gamestate.rpc_id(1, "lobby_left", gamestate.my_secret)
	gamestate.my_secret = ""
	$Panel2.hide()



func _on_Start_pressed():
	gamestate.rpc_id(1, "start_game", gamestate.my_secret)


func _on_Ready_pressed():
	pass # Replace with function body.
