extends Position3D

var is_holding = null
puppet var puppet_hold = null

func _ready():
	self.set_custom_multiplayer(owner.webrtc.mp)
	
func _process(delta):
	if !is_network_master():
		is_holding = puppet_hold
		if is_holding == null:
			for child in get_children():
				child.visible = false
		else:
			get_node("%s" %is_holding).visible = true
			
		
func hold(type: String):
	if is_network_master():
		get_node("%s" %type).visible = true
		is_holding = type
		rset_unreliable("puppet_hold", type)

func remove(type):
	if is_network_master():
		get_node("%s" %type).visible = false
		is_holding = null
		rset_unreliable("puppet_hold", null)
