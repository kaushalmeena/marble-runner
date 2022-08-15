extends KinematicBody

const GRAVITY = 2;
const MOVE_SPEED = 5
const JUMP_SPEED = 30

const LANES = [-10, -5,  0, 5, 10]

var velocity = Vector3.ZERO
var distance = 0;
var lane_cnt = LANES.size()
var lane_idx = 2;

func _ready():
	pass # Replace with function body.
	
func _get_input():
	if Input.is_action_just_pressed('ui_left') and lane_idx > 0:
		lane_idx -= 1
	elif Input.is_action_just_pressed('ui_right') and lane_idx < lane_cnt - 1:
		lane_idx += 1
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y += JUMP_SPEED

func _check_collision():
	if (get_slide_count() > 1):
		Global.goto_scene('res://menus/DeathMenu.tscn')

func _move():
	distance = LANES[lane_idx] - global_transform.origin.x
	if (abs(distance) > 0.1):
		velocity.x = distance * MOVE_SPEED
	else:
		velocity.x = 0
	velocity.y -= GRAVITY
	velocity = move_and_slide(velocity, Vector3.UP)

func _physics_process(_delta):
	_get_input()
	_move()
	_check_collision()
	
	
		
		
	
