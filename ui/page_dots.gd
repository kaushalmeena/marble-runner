class_name PageDots
extends Control
## A row of dots, one per page, with the current one stretched into a bar.

const DOT := 8.0
const BAR := 26.0
const GAP := 9.0
const ON := Color(1.0, 0.79, 0.24)
const OFF := Color(1.0, 1.0, 1.0, 0.3)

var count: int = 1:
	set(value):
		count = maxi(1, value)
		# Sized for the count alone, so moving the bar never changes the width.
		custom_minimum_size = Vector2(BAR + (count - 1) * (DOT + GAP), DOT)
		queue_redraw()

var current: int = 0:
	set(value):
		current = value
		queue_redraw()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER


func _draw() -> void:
	var x := 0.0
	for index in count:
		var width := BAR if index == current else DOT
		var color := ON if index == current else OFF
		draw_circle(Vector2(x + DOT / 2.0, DOT / 2.0), DOT / 2.0, color)
		draw_circle(Vector2(x + width - DOT / 2.0, DOT / 2.0), DOT / 2.0, color)
		draw_rect(Rect2(x + DOT / 2.0, 0.0, width - DOT, DOT), color)
		x += width + GAP
