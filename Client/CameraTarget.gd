extends Position3D


func _ready():
	set_as_toplevel(true)

func _process(_delta):
	rotation_degrees.x = owner.angle
	var target = get_parent().get_global_transform().origin
	var pos = target + Vector3(0,0,owner.distance)
	pos.y = owner.height
	set_translation(pos)
