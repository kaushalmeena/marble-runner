class_name SkinChip
extends Button
## One skin in the shop's row of swatches: its colour, and whether it is
## locked, owned or worn.

enum State { LOCKED, OWNED, EQUIPPED }

const SIDE := 50.0
const RING := Color(1.0, 0.79, 0.24)

var state: State = State.LOCKED:
	set(value):
		state = value
		queue_redraw()

## True for the skin on show in the big preview.
var current: bool = false:
	set(value):
		current = value
		queue_redraw()

var _color: Color


func _init(color: Color) -> void:
	_color = color
	theme_type_variation = &"RoundButton"
	custom_minimum_size = Vector2(SIDE, SIDE + 5.0)
	focus_mode = Control.FOCUS_NONE


func _draw() -> void:
	# The face of the button is the square above its lip.
	var center := Vector2(size.x / 2.0, (size.y - 5.0) / 2.0)
	var radius := SIDE * 0.3
	draw_circle(center, radius, _color if state != State.LOCKED else _color.darkened(0.45))
	draw_circle(center + Vector2(-radius, -radius) * 0.34, radius * 0.24,
		Color(1.0, 1.0, 1.0, 0.5 if state != State.LOCKED else 0.2))
	if current:
		draw_arc(center, SIDE * 0.42, 0.0, TAU, 40, RING, 3.0, true)
	if state == State.EQUIPPED:
		var tick := center + Vector2(radius, radius) * 0.75
		draw_circle(tick, 8.0, RING)
		draw_polyline(PackedVector2Array([
			tick + Vector2(-4.0, 0.0), tick + Vector2(-1.0, 3.0), tick + Vector2(4.0, -3.0)]),
			Icon.DARK, 2.0, true)
	elif state == State.LOCKED:
		var body := Rect2(center + Vector2(-5.0, -1.0), Vector2(10.0, 8.0))
		draw_rect(body, Icon.LIGHT)
		draw_arc(center + Vector2(0.0, -1.0), 3.5, PI, TAU, 12, Icon.LIGHT, 2.0, true)
