extends KinematicBody

onready var Game = get_node("/root/Game")

var gravity: float = 2.0
var move_speed: float = 5.0
var jump_speed: float = 30.0

var lane_idx: int = 2

var velocity: Vector3 = Vector3.ZERO


func _ready() -> void:
	pass


func _get_input() -> void:
	if Input.is_action_just_pressed("ui_left") and lane_idx > 0:
		lane_idx -= 1
	elif Input.is_action_just_pressed("ui_right") and lane_idx < Game.lanes.size() - 1:
		lane_idx += 1


func _move() -> void:
	var distance: float = Game.lanes[lane_idx] - global_transform.origin.x
	if abs(distance) > 0.1:
		velocity.x = distance * move_speed
	else:
		velocity.x = 0
	move_and_slide(velocity, Vector3.UP)


func _physics_process(_delta: float) -> void:
	_get_input()
	_move()
