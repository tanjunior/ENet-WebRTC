extends RigidBody
var mp
var game : Node
export var type = ""
puppet var puppet_state

func _ready():
	self.set_custom_multiplayer(mp)
	var vec = Vector3(0,0,2).rotated(Vector3.UP, rotation.y)
	apply_impulse(global_transform.origin, vec)

func _integrate_forces(state):
	if is_network_master():
		rset_unreliable("puppet_state", state.transform)
	else:
		if puppet_state != null:
			state.transform = puppet_state
			
func interact():
	rpc("kill")
#	if is_network_master():
#	else:
#		rpc_id(1, "kill")
##		queue_free()
	
remotesync func kill():
	queue_free()
