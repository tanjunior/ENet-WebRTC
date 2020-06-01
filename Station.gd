extends StaticBody
var mp
var game : Node
var current_item = null
puppet var puppet_hold = null

enum TYPE {
	Ball,
	Cube
}

func _ready():
	game = owner
	mp = owner.get_node("webrtc").mp
	self.set_custom_multiplayer(mp)

func interact(type = null):
	if type != null:
		rpc("place", type)
	else:
		rpc("pick")

remotesync func place(type):
	current_item = type
	get_node("StationTop/%s" %current_item).visible = true

remotesync func pick():
	get_node("StationTop/%s" %current_item).visible = false
	current_item = null
