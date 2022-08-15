extends KinematicBody

const GRAVITY: float = 2.0
const MOVE_SPEED: float = 5.0
const JUMP_SPEED: float = 30.0

const LANES: Array = [-10, -5, 0, 5, 10]

var lane_cnt: int = LANES.size()
var lane_idx: int = 2

var velocity: Vector3 = Vector3.ZERO


func _ready() -> void:
	pass


func _get_input() -> void:
	if Input.is_action_just_pressed("ui_left") and lane_idx > 0:
		lane_idx -= 1
	elif Input.is_action_just_pressed("ui_right") and lane_idx < lane_cnt - 1:
		lane_idx += 1
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y += JUMP_SPEED


func _check_collision() -> void:
	if get_slide_count() > 1:
		Global.goto_scene("res://menus/DeathMenu.tscn")


func _move() -> void:
	var distance: float = LANES[lane_idx] - global_transform.origin.x
	if abs(distance) > 0.1:
		velocity.x = distance * MOVE_SPEED
	else:
		velocity.x = 0
	velocity.y -= GRAVITY
	velocity = move_and_slide(velocity, Vector3.UP)


func _physics_process(_delta: float) -> void:
	_get_input()
	_move()
	_check_collision()
