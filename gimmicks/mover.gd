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
