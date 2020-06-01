extends Node


onready var button = $Panel/Button
onready var popup = $Panel/AcceptDialog
var all_peers_connected = false
var all_peers_ready = false
var Player = preload("res://BallCharacter.tscn")
var Ball = preload("res://BallObject.tscn")
var Cube = preload("res://CubeObject.tscn")
onready var world = $World
var ready_players : Dictionary
onready var webrtc = $webrtc
var my_id
var object_count = 0


func _ready():
	self.set_custom_multiplayer(webrtc.mp)
	my_id = webrtc.mp.get_network_unique_id()
	webrtc.webrtc_multiplayer.connect("peer_connected", self, "_on_peer_connected")
	$Panel/Label.text = str("MY PEER_ID: %s" %my_id)
	randomize()
	spawn_player(my_id)
	$Panel.hide()

func game_start():
	button.disabled = false
#	spawn_player(webrtc.mp.get_network_unique_id())
#	for user_id in webrtc.webrtc_peers:
#		var peer_id = gamestate.players[user_id].peer_id
#		spawn_player(peer_id)

puppet func spawn_player(peer_id):
	var player = Player.instance()
	player.name = str(peer_id)
	player.set_network_master(peer_id)
	player.game = self
	player.webrtc = webrtc
	world.add_child(player)
	var spawn_point = get_node("World/SpawnPoints/%s" %peer_id).global_transform.origin
	player.global_transform.origin = spawn_point
	
	if player.get_network_master() == webrtc.mp.get_network_unique_id():
		print("set camera")
		$InterpolatedCamera.target = player.camera_target
	
func _on_Button_pressed():
	rpc("test")


func _on_Button2_pressed():
	webrtc.webrtc_multiplayer.disconnect("peer_connected", self, "_on_peer_connected")
	webrtc.leave()



func _process(_delta):
	if !all_peers_connected:
		poll_status()
			
	if !all_peers_ready:
		if ready_players.size() == webrtc.webrtc_peers_connected.size():
			game_start()
			all_peers_ready = true

func poll_status():
	if !all_peers_connected:
		$Panel/ItemList.clear()
		for user_id in webrtc.webrtc_peers_connected:
			var player = gamestate.players[user_id]
			if webrtc.webrtc_peers_connected[user_id] == true:
				$Panel/ItemList.add_item("[%s]%s:Connected" %[player.peer_id,player.name])
				continue
			$Panel/ItemList.add_item("[%s]%s:Connecting" %[player.peer_id,player.name])
	
		for status in webrtc.webrtc_peers_connected.values():
			if status == false:
				return
				
		all_peers_connected = true
		rpc("ready")
	

remote func ready():
	var caller_id = webrtc.mp.get_rpc_sender_id()
	var player_name = webrtc.get_player_name_from_peer_id(caller_id)
	ready_players[caller_id] = true
	$Panel/ItemList2.add_item("[%s]%s:READY" %[caller_id,player_name])
	
func _on_peer_connected(peer_id: int):
	for user_id in gamestate.players:
		if user_id == gamestate.my_id:
			continue
		var player = gamestate.players[user_id]
		if player.peer_id == peer_id:
			webrtc.webrtc_peers_connected[user_id] = true
			spawn_player(peer_id)

	# We have a WebRTC peer for each connection to another player, so we'll have one less than
	# the number of players (ie. no peer connection to ourselves).

remote func test():
	var caller_id = webrtc.mp.get_rpc_sender_id()
	popup.dialog_text = "[%s] says hi" %[caller_id]
	popup.popup()

#remote func puppet_movement(_position, velocity):
#	var caller_id = webrtc.mp.get_rpc_sender_id()
#	var _puppet = get_node("World/%s"%caller_id)
#	_puppet.puppet_pos = _position
#	_puppet.puppet_vel = velocity
	
remotesync func spawn_object(pos, rot, type):
	object_count+= 1
	var object
	match type:
		"Ball":
			object = Ball.instance()
		"Cube":
			object = Cube.instance()

	object.mp = webrtc.mp
	object.set_network_master(1)
	object.game = self
	object.name = str(object_count)
	object.set_rotation(rot)
	$World/Objects.add_child(object)
	object.global_transform.origin = pos
