extends Spatial

onready var label = $Label
onready var character = $BallCharacter


func _ready():
	$InterpolatedCamera.target = character.camera_target
	
func _process(delta):
	label.text = "Direction: %s" %str(character.direction)
	$Label2.text = "Velocity: %s" %str(character.velocity)
	$Label3.text = "Blend Amount: %s" %str(character.blend)
