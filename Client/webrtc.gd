extends Node

var webrtc_multiplayer : WebRTCMultiplayer
var webrtc_peer : WebRTCPeerConnection
var webrtc_peers : Dictionary
var webrtc_peers_connected : Dictionary
var options = {
	"negotiated": true, # When set to true (default off), means the channel is negotiated out of band. "id" must be set too. data_channel_received will not be called.
	"id": 1, # When "negotiated" is true this value must also be set to the same value on both peer.

#	# Only one of maxRetransmits and maxPacketLifeTime can be specified, not both. They make the channel unreliable (but also better at real time).
#	"maxRetransmits": 1, # Specify the maximum number of attempt the peer will make to retransmits packets if they are not acknowledged.
#	"maxPacketLifeTime": 100, # Specify the maximum amount of time before giving up retransmitions of unacknowledged packets (in milliseconds).
#	"ordered": true, # When in unreliable mode (i.e. either "maxRetransmits" or "maxPacketLifetime" is set), "ordered" (true by default) specify if packet ordering is to be enforced.
#
#	"protocol": "my-custom-protocol", # A custom sub-protocol string for this channel.
}

func _ready():
	pass # Replace with function body.

func init_rtc():
	_create_webrtc_multiplayer()
	webrtc_multiplayer.initialize(gamestate.players[gamestate.my_id].peer_id)
	get_tree().set_network_peer(webrtc_multiplayer)
	peer_to_peer()
	
func _create_webrtc_multiplayer():
	webrtc_multiplayer = WebRTCMultiplayer.new()
# warning-ignore:return_value_discarded
	webrtc_multiplayer.connect("peer_connected", self, "_on_webrtc_peer_connected")
# warning-ignore:return_value_discarded
	webrtc_multiplayer.connect("peer_disconnected", self, "_on_webrtc_peer_disconnected")
	
func peer_to_peer():
	for p in gamestate.players:
		if p == gamestate.my_id:
			continue
		_webrtc_connect_peer(p, gamestate.players[p])
		
func _webrtc_connect_peer(p, u: Dictionary):
	print("connecting peer")
	# Don't add the same peer twice!
	if webrtc_peers.has(u):
		return
	
	webrtc_peer = WebRTCPeerConnection.new()
	webrtc_peer.initialize({
		"iceServers": [{ "urls": ["stun:stun.l.google.com:19302"] }]
	})
# warning-ignore:return_value_discarded
	webrtc_peer.connect("data_channel_received", self, "_on_data_channel_received")
# warning-ignore:return_value_discarded
	webrtc_peer.connect("session_description_created", self, "_on_webrtc_peer_session_description_created", [p, u.peer_id])
# warning-ignore:return_value_discarded
	webrtc_peer.connect("ice_candidate_created", self, "_on_webrtc_peer_ice_candidate_created", [p, u.peer_id])

	webrtc_peers[p] = webrtc_peer
	print("the user peer_id is %s" %u.peer_id)
	webrtc_multiplayer.add_peer(webrtc_peer, u.peer_id)
	
	if gamestate.my_id != p:
		print("%s != %s" %[gamestate.my_id, p])
		var result = webrtc_peer.create_offer()
		if result != OK:
			emit_signal("error", "Unable to create WebRTC offer")

func _on_webrtc_peer_session_description_created(type : String, sdp : String, user_id, peer_id):
	webrtc_peer = webrtc_peers[user_id]
	webrtc_peer.set_local_description(type, sdp)

	print("[_on_webrtc_peer_session_description_created] %s" %user_id)
	# Send this data to the peer so they can call call .set_remote_description().
	var data = {
				method = "set_remote_description",
				target = user_id,
				type = type,
				sdp = sdp,
			}
	rpc_id(peer_id, "rtc_handshake", data)
	
func _on_webrtc_peer_ice_candidate_created(media : String, index : int, name : String, user_id, peer_id):
	print("[_on_webrtc_peer_ice_candidate_created] %s" %user_id)
	# Send this data to the peer so they can call .add_ice_candidate()
	var data = {
				method = "add_ice_candidate",
				target = user_id,
				media = media,
				index = index,
				name = name,
			}
	rpc_id(peer_id, "rtc_handshake", data)

remote func rtc_handshake(data):
	if data.target == gamestate.my_id:
		var user_id = get_tree().get_rpc_sender_id()
		webrtc_peer = webrtc_peers[user_id]
		
		match data.method:
			'set_remote_description':
				webrtc_peer.set_remote_description(data.type, data.sdp)
				print("[set_remote_description] on user_id")
			'add_ice_candidate':
				webrtc_peer.add_ice_candidate(data.media, data.index, data.name)
				print("[add_ice_candidate] on user_id")
			'reconnect':
				webrtc_multiplayer.remove_peer(gamestate.players[user_id].peer_id)
#						_webrtc_reconnect_peer(players[session_id])

func _on_webrtc_peer_connected(peer_id: int):
	for user_id in gamestate.players:
		if gamestate.players[user_id].peer_id == peer_id:
			webrtc_peers_connected[user_id] = true

	# We have a WebRTC peer for each connection to another player, so we'll have one less than
	# the number of players (ie. no peer connection to ourselves).
	print("[_on_webrtc_peer_connected]")
	emit_signal("game_start")
