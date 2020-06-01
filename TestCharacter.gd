extends KinematicBody


const SPEED = 2
const ACCELERATION = 3
const FRICTION = 4
const GRAVITY = -9.8
const JUMP_FORCE = 5
var velocity = Vector3.ZERO
var direction = Vector3.ZERO
var is_moving = false
var is_jumping = false
var blend
export var distance = 2
export var height = 3
export var angle = -55

puppet var puppet_pos
puppet var puppet_vel = Vector3.ZERO

onready var camera_target: NodePath = $CameraTarget.get_path()

func _ready():
	puppet_pos = global_transform.origin

func _physics_process(delta):
	movement(delta)
	animation(velocity)
	

	
func _input(event):
	if $AnimationTree.get("parameters/Jump_Shot/active") == false:
		is_jumping = false
		
	var jump = Input.is_action_pressed("jump")
	if jump and !is_jumping and is_on_floor():
		$AnimationTree.set("parameters/Jump_Shot/active", true)
		is_jumping =  true
		velocity.y = JUMP_FORCE
		
func movement(delta):
	direction = Vector3.ZERO
	direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	direction.z = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	if direction == Vector3.ZERO:
		is_moving = false
	else:
		is_moving = true
	direction = direction.normalized()
	velocity.y += delta * GRAVITY 
	var new_pos = direction * SPEED
	var force = FRICTION
	if direction.dot(velocity) > 0:
		force = ACCELERATION
	velocity = lerp(velocity, new_pos, delta * force)
	velocity = move_and_slide(velocity, Vector3(0,1,0))
	
	var player_rot = get_rotation()
	if is_moving:
		var angle = atan2(velocity.x, velocity.z)
		player_rot.y = angle
		set_rotation(player_rot)

func animation(hv):
	blend = hv.length()/ SPEED
	$AnimationTree.set("parameters/Idle_Running/blend_amount", blend)
