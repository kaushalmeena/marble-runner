class_name SwipeDetector
extends Node
## Turns pointer gestures into lane changes and jumps.
##
## Only mouse events are read. Godot emulates mouse from touch by default, so
## one code path covers desktop, the web build and phones; handling both would
## make every real touch fire twice.

signal swiped_left
signal swiped_right
signal swiped_up
signal tapped

## Movement under this counts as a tap rather than a swipe.
@export var tap_radius_pixels: float = 26.0
## Movement over this counts as a swipe. The gap between the two is dead space,
## so a sloppy tap is never read as a flick.
@export var swipe_distance_pixels: float = 56.0

var _pressed_at: Vector2 = Vector2.ZERO
var _tracking: bool = false


func _unhandled_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button == null or button.button_index != MOUSE_BUTTON_LEFT:
		return
	if button.pressed:
		_pressed_at = button.position
		_tracking = true
		return
	if not _tracking:
		return
	_tracking = false
	_resolve(button.position - _pressed_at)
	get_viewport().set_input_as_handled()


func _resolve(motion: Vector2) -> void:
	var distance := motion.length()
	if distance <= tap_radius_pixels:
		tapped.emit()
		return
	if distance < swipe_distance_pixels:
		return
	if absf(motion.x) > absf(motion.y):
		if motion.x < 0.0:
			swiped_left.emit()
		else:
			swiped_right.emit()
	elif motion.y < 0.0:
		swiped_up.emit()
