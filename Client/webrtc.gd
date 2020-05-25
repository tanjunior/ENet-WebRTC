extends Node

var webrtc_multiplayer : WebRTCMultiplayer
var webrtc_peer : WebRTCPeerConnection
var webrtc_peers : Dictionary #Dictionary of WebRTCPeerConnection objects
var webrtc_peers_connected : Dictionary
var mp : MultiplayerAPI = MultiplayerAPI.new()
#signal completed
var poll = false
var game

func _ready():
	game = self.owner
	gamestate.connect("rtc_handshake", self, "_on_rtc_handshake")
	init_rtc()

func _process(_delta):
	mp.poll()
	if poll:
		webrtc_peer.poll()
	
func init_rtc():
#	leave()
	
	create_webrtc_multiplayer()
	webrtc_multiplayer.initialize(gamestate.my_peer_id)
	mp.set_network_peer(webrtc_multiplayer)
	mp.set_root_node(game) #very important do not remove
	peer_to_peer()
	for user_id in gamestate.players:
		if user_id == gamestate.my_id:
			continue
		webrtc_peers_connected[user_id] = false
	
func create_webrtc_multiplayer():
	webrtc_multiplayer = WebRTCMultiplayer.new()
#	webrtc_multiplayer.connect("peer_connected", self, "_on_peer_connected")
# warning-ignore:return_value_discarded
	webrtc_multiplayer.connect("peer_disconnected", self, "_on_peer_disconnected")
	
func peer_to_peer():
	for user_id in gamestate.players:
		if user_id == gamestate.my_id:
			continue
		_webrtc_connect_peer(user_id, gamestate.players[user_id])
		
func _webrtc_connect_peer(user_id, u: Dictionary):
	# Don't add the same peer twice!
	if webrtc_peers.has(user_id):
		return
	
	webrtc_peer = WebRTCPeerConnection.new()
	webrtc_peer.initialize({
		"iceServers": [{ "urls": ["stun:stun.l.google.com:19302"] }]
	})
	poll = true
#	webrtc_peer.create_data_channel("hand_shake", {"id": 1, "negotiated": true})
# warning-ignore:return_value_discarded
#	webrtc_peer.connect("data_channel_received", self, "_on_data_channel_received")
# warning-ignore:return_value_discarded
	webrtc_peer.connect("session_description_created", self, "_on_session_description_created", [user_id])
# warning-ignore:return_value_discarded
	webrtc_peer.connect("ice_candidate_created", self, "_on_ice_candidate_created", [user_id])

	webrtc_peers[user_id] = webrtc_peer
	webrtc_multiplayer.add_peer(webrtc_peer, u.peer_id)
	
	if gamestate.my_id != user_id:
		var err = webrtc_peer.create_offer()
		if err == OK:
#			print("created offer for %s" %[user_id])
			pass

func _on_session_description_created(type : String, sdp : String, user_id):
#	print("[_on_session_description_created] %s for %s" %[type,user_id])
	webrtc_peer = webrtc_peers[user_id]
	var err = webrtc_peer.set_local_description(type, sdp)
	if err != OK:
		print("[set_local_description]%s" %err)
	
	# Send this data to the peer so they can call call .set_remote_description().
	var data = {
				method = "set_remote_description",
				target = user_id,
				type = type,
				sdp = sdp,
			}
	if gamestate.lobbies[gamestate.my_lobby_id].players.has(user_id):
		gamestate.rpc_id(user_id, "rtc_handshake", data)
	
func _on_ice_candidate_created(media : String, index : int, name : String, user_id):
#	print("[_on_ice_candidate_created] %s" %user_id)
	# Send this data to the peer so they can call .add_ice_candidate()
	var data = {
				method = "add_ice_candidate",
				target = user_id,
				media = media,
				index = index,
				name = name,
			}
	if gamestate.lobbies[gamestate.my_lobby_id].players.has(user_id):
		gamestate.rpc_id(user_id, "rtc_handshake", data)

func _on_rtc_handshake(caller_id, data):
	if data.target == gamestate.my_id:
		webrtc_peer = webrtc_peers[caller_id]
		
		match data.method:
			'set_remote_description':
				var err = webrtc_peer.set_remote_description(data.type, data.sdp)
				if err != OK:
					print("[set_remote_description] failed")
				else:
					pass
#					print("[set_remote_description] on %s" %caller_id)
			'add_ice_candidate':
				var err = webrtc_peer.add_ice_candidate(data.media, data.index, data.name)
				if err != OK:
#					print("[add_ice_candidate] failed")
					retry(caller_id, gamestate.players[caller_id])
				else:
					pass
#					print("[add_ice_candidate] on %s" %caller_id)
#			'reconnect':
#				webrtc_multiplayer.remove_peer(gamestate.players[caller_id].peer_id)
##						_webrtc_reconnect_peer(players[session_id])
func retry(user_id, u):
	var _webrtc_peer : WebRTCPeerConnection = webrtc_peers[user_id]
	webrtc_multiplayer.remove_peer(u.peer_id)
	_webrtc_peer.disconnect("session_description_created", self, "_on_session_description_created")
	_webrtc_peer.disconnect("ice_candidate_created", self, "_on_ice_candidate_created")
	_webrtc_peer.close()
	_webrtc_peer.initialize({
		"iceServers": [{ "urls": ["stun:stun.l.google.com:19302"] }]
	})
# warning-ignore:return_value_discarded
	webrtc_peer.connect("session_description_created", self, "_on_session_description_created", [user_id])
# warning-ignore:return_value_discarded
	webrtc_peer.connect("ice_candidate_created", self, "_on_ice_candidate_created", [user_id])

	webrtc_multiplayer.add_peer(webrtc_peer, u.peer_id)
	
	if gamestate.my_id != user_id:
		var err = webrtc_peer.create_offer()
		if err == OK:
#			print("Retry created offer for %s" %[user_id])
			pass

func _on_peer_disconnected(peer_id: int):
	print("PEER %s DISCONNECTED" %peer_id)
	for user_id in gamestate.players:
		if gamestate.players[user_id].peer_id == peer_id:
			webrtc_multiplayer.remove_peer(peer_id)
			webrtc_peers_connected[user_id] = false
			webrtc_peer = webrtc_peers[user_id]
			webrtc_peer.disconnect("session_description_created", self, "_on_session_description_created")
			webrtc_peer.disconnect("ice_candidate_created", self, "_on_ice_candidate_created")
			webrtc_peers.erase(user_id)

func get_player_name_from_peer_id(peer_id):
	for user_id in gamestate.players:
		var player_data = gamestate.players[user_id]
		if player_data.peer_id == peer_id:
			return player_data.name

func leave():
	poll = false
	if webrtc_multiplayer:
#		webrtc_multiplayer.disconnect("peer_connected", self, "_on_peer_connected")
		webrtc_multiplayer.disconnect("peer_disconnected", self, "_on_peer_disconnected")
		webrtc_multiplayer.close()
		webrtc_multiplayer = null
		
		mp.set_network_peer(null)
		mp.clear()
		webrtc_peer = null
		
		webrtc_peers.clear()
		gamestate.players.clear()
		webrtc_peers_connected.clear()
		

		gamestate.rpc_id(1, "lobby_left", gamestate.my_lobby_id)
#		yield(get_tree().create_timer(1.0),"timeout")
		gamestate.my_lobby_id = ""
		get_tree().change_scene("res://Main.tscn")
