class_name Mover
extends AnimatableBody3D
## A platform that glides back and forth between two points.
##
## It parks at each end before setting off again. That pause is what makes it
## possible to board without matching speed.

## Fraction of each one-way trip spent parked at the end.
const DWELL := 0.12

## Offset from the starting position to the far end.
var travel := Vector3.ZERO
## Seconds for a full there-and-back.
var period: float = 8.0
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
	var before := _offset()
	_time += delta
	_apply()
	# Measured from the motion curve rather than from the node's position: a
	# body synced to physics does not report its new position until later.
	velocity = (_offset() - before) / delta


func _apply() -> void:
	position = _origin + _offset()


## Where the platform is along its travel at the current time.
func _offset() -> Vector3:
	var cycle := fposmod(_time / maxf(period, 0.1) + phase, 1.0)
	# A triangle wave, there and back, with the ends clipped flat so the
	# platform parks for a moment, then smoothed so it eases in and out.
	var triangle := 1.0 - absf(cycle * 2.0 - 1.0)
	var along := clampf((triangle - DWELL) / (1.0 - 2.0 * DWELL), 0.0, 1.0)
	return travel * smoothstep(0.0, 1.0, along)
