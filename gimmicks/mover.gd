class_name Mover
extends AnimatableBody3D
## A platform that glides back and forth between two points.
##
## Eased rather than linear, so it pauses at each end. That pause is what makes
## it possible to board without matching speed.

## Offset from the starting position to the far end.
var travel := Vector3.ZERO
## Seconds for a full there-and-back.
var period: float = 6.0
## Starting point in the cycle, 0..1, to put neighbouring movers out of step.
var phase: float = 0.0

## How fast the platform is travelling right now. The marble reads this so it
## can be carried along instead of left behind.
var velocity := Vector3.ZERO

var _origin := Vector3.ZERO
var _time: float = 0.0


func _ready() -> void:
	_origin = position
	_apply()


func _physics_process(delta: float) -> void:
	_time += delta
	_apply()


func _apply() -> void:
	var cycle := _time / maxf(period, 0.1) + phase
	position = _origin + travel * (0.5 - 0.5 * cos(cycle * TAU))
	# The derivative of the line above, rather than a difference of positions:
	# a body synced to physics does not report its new position until later.
	velocity = travel * (0.5 * sin(cycle * TAU) * TAU / maxf(period, 0.1))
