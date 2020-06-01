extends StaticBody
var mp
var game : Node
export var type = ""
onready var anim = $AnimationPlayer

func _ready():
	game = owner
	mp = owner.get_node("webrtc").mp
	set_custom_multiplayer(mp)

func interact():
	rpc("open")
	
remotesync func open():
	var caller_id = mp.get_rpc_sender_id()
	var attach_point : Node = game.get_node("World/%s/AttachPoint" %caller_id)
	anim.play("Open")
	attach_point.hold(type)
