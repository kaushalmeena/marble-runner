class_name StarRow
extends Control
## Three stars, some of them lit.
##
## Drawn rather than typed: the project font has no star glyph, and a missing
## glyph renders as an empty box.

const LIT := Color(1.0, 0.79, 0.24)
const UNLIT := Color(1.0, 1.0, 1.0, 0.16)
const COUNT := 3

@export var star_size: float = 26.0:
	set(value):
		star_size = value
		custom_minimum_size = Vector2(star_size * COUNT + star_size * 0.25 * (COUNT - 1), star_size)
		queue_redraw()

var filled: int = 0:
	set(value):
		filled = clampi(value, 0, COUNT)
		queue_redraw()


func _init(size: float = 26.0, lit: int = 0) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	star_size = size
	filled = lit


func _draw() -> void:
	var radius := star_size / 2.0
	for index in COUNT:
		var center := Vector2(radius + index * star_size * 1.25, radius)
		var points := PackedVector2Array()
		for corner in 10:
			var reach := radius if corner % 2 == 0 else radius * 0.45
			var angle := -PI / 2.0 + corner * PI / 5.0
			points.append(center + Vector2(cos(angle), sin(angle)) * reach)
		draw_colored_polygon(points, LIT if index < filled else UNLIT)
