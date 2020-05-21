extends Node

var webrtc_multiplayer : WebRTCMultiplayer
var webrtc_peer : WebRTCPeerConnection
var webrtc_peers : Dictionary #Dictionary of WebRTCPeerConnection objects
var webrtc_peers_connected : Dictionary
var webrtc : MultiplayerAPI = MultiplayerAPI.new()
signal game_start
var poll = false

func _ready():
	var game:Node = self
	webrtc.set_root_node(game)
	game.set_custom_multiplayer(webrtc)
	gamestate.connect("rtc_handshake", self, "_on_rtc_handshake")
	init_rtc()
	
func _process(_delta):
	webrtc.poll()
	
func init_rtc():
	poll = true
	_create_webrtc_multiplayer()
	webrtc_multiplayer.initialize(gamestate.my_peer_id)
	webrtc.set_network_peer(webrtc_multiplayer)
#	get_parent().set_network_peer(webrtc_multiplayer)
	peer_to_peer()
	
func _create_webrtc_multiplayer():
	webrtc_multiplayer = WebRTCMultiplayer.new()
# warning-ignore:return_value_discarded
	webrtc_multiplayer.connect("peer_connected", self, "_on_webrtc_peer_connected")
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
			print("created offer for %s" %[user_id])

func _on_session_description_created(type : String, sdp : String, user_id):
	print("[_on_session_description_created] %s for %s" %[type,user_id])
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
	gamestate.rpc_id(user_id, "rtc_handshake", data)
	
func _on_ice_candidate_created(media : String, index : int, name : String, user_id):
	print("[_on_ice_candidate_created] %s" %user_id)
	# Send this data to the peer so they can call .add_ice_candidate()
	var data = {
				method = "add_ice_candidate",
				target = user_id,
				media = media,
				index = index,
				name = name,
			}
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
					print("[set_remote_description] on %s" %caller_id)
			'add_ice_candidate':
				var err = webrtc_peer.add_ice_candidate(data.media, data.index, data.name)
				if err != OK:
					print("[add_ice_candidate] failed")
				else:
					print("[add_ice_candidate] on %s" %caller_id)
#			'reconnect':
#				webrtc_multiplayer.remove_peer(gamestate.players[caller_id].peer_id)
##						_webrtc_reconnect_peer(players[session_id])

func _on_webrtc_peer_connected(peer_id: int):
	for user_id in gamestate.players:
		if gamestate.players[user_id].peer_id == peer_id:
			webrtc_peers_connected[user_id] = true
			
			print("[THIS IS MY NAME ID FOR RPC CALLS]%s" %webrtc.get_network_unique_id())
#			rpc_id(peer_id, "test", gamestate.my_id)

	# We have a WebRTC peer for each connection to another player, so we'll have one less than
	# the number of players (ie. no peer connection to ourselves).
	print("[_on_webrtc_peer_connected]")
	emit_signal("game_start")

func _on_peer_disconnected(peer_id: int):
	pass
	
remote func test():
	var caller_id = webrtc.get_rpc_sender_id()
	var my_id = webrtc.get_network_unique_id()
	print("[%s] hi %s" %[caller_id, my_id])
