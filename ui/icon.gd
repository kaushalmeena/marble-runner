class_name Icon
extends Control
## A small pictogram, drawn rather than loaded.
##
## The project font has no arrows, stars or locks, and a missing glyph renders
## as an empty box. Drawing them keeps every icon crisp at any size and the
## same weight as the text beside it.

enum Kind {
	NONE, PLAY, LEVELS, SHOP, QUIT, LEFT, RIGHT, BACK, NEXT, LOCK, DIAMOND, STAR,
	CHECK, RESTART, HOME, GEM,
}

const LIGHT := Color(1.0, 1.0, 1.0, 0.94)
## For the amber primary button, whose label is dark.
const DARK := Color(0.17, 0.1, 0.01)
const GOLD := Color(1.0, 0.79, 0.24)
## The purse is counted in gems, and this is their colour everywhere.
const GEM_BLUE := Color(0.35, 0.85, 1.0)
## The secret diamond's mark: near white, so it is never taken for a gem.
const DIAMOND_WHITE := Color(0.86, 0.95, 1.0)

var kind: Kind = Kind.NONE:
	set(value):
		kind = value
		queue_redraw()

var color: Color = LIGHT:
	set(value):
		color = value
		queue_redraw()


func _init(what: Kind = Kind.NONE, side: float = 22.0, tint: Color = LIGHT) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(side, side)
	size = custom_minimum_size
	kind = what
	color = tint


func _draw() -> void:
	var s := minf(size.x, size.y)
	var stroke := s * 0.13
	match kind:
		Kind.PLAY:
			_fill([Vector2(0.26, 0.14), Vector2(0.86, 0.5), Vector2(0.26, 0.86)])
		Kind.LEVELS:
			for cell in [Vector2(0.12, 0.12), Vector2(0.56, 0.12),
					Vector2(0.12, 0.56), Vector2(0.56, 0.56)]:
				draw_rect(Rect2(cell * s, Vector2(0.32, 0.32) * s), color)
		Kind.SHOP:
			draw_rect(Rect2(Vector2(0.14, 0.38) * s, Vector2(0.72, 0.5) * s), color)
			draw_arc(Vector2(0.5, 0.4) * s, s * 0.2, PI, TAU, 16, color, stroke, true)
		Kind.QUIT:
			draw_arc(Vector2(0.5, 0.54) * s, s * 0.34, -PI * 0.22, PI * 1.22, 24, color,
				stroke, true)
			_line([Vector2(0.5, 0.08), Vector2(0.5, 0.5)], stroke)
		Kind.LEFT:
			_line([Vector2(0.62, 0.14), Vector2(0.28, 0.5), Vector2(0.62, 0.86)], stroke * 1.3)
		Kind.RIGHT:
			_line([Vector2(0.38, 0.14), Vector2(0.72, 0.5), Vector2(0.38, 0.86)], stroke * 1.3)
		Kind.BACK:
			_line([Vector2(0.46, 0.18), Vector2(0.14, 0.5), Vector2(0.46, 0.82)], stroke)
			_line([Vector2(0.16, 0.5), Vector2(0.88, 0.5)], stroke)
		Kind.NEXT:
			_line([Vector2(0.54, 0.18), Vector2(0.86, 0.5), Vector2(0.54, 0.82)], stroke)
			_line([Vector2(0.12, 0.5), Vector2(0.84, 0.5)], stroke)
		Kind.LOCK:
			draw_rect(Rect2(Vector2(0.18, 0.46) * s, Vector2(0.64, 0.44) * s), color)
			draw_arc(Vector2(0.5, 0.46) * s, s * 0.2, PI, TAU, 16, color, stroke, true)
		Kind.DIAMOND:
			# The classic cut, side on: a flat-topped crown over a point, with
			# the facets picked out a shade darker.
			_fill([Vector2(0.24, 0.14), Vector2(0.76, 0.14), Vector2(0.98, 0.4),
				Vector2(0.5, 0.94), Vector2(0.02, 0.4)])
			var shade := color.darkened(0.22)
			draw_colored_polygon(_scaled([Vector2(0.02, 0.4), Vector2(0.34, 0.4),
				Vector2(0.5, 0.94)]), shade)
			draw_colored_polygon(_scaled([Vector2(0.66, 0.4), Vector2(0.98, 0.4),
				Vector2(0.5, 0.94)]), shade)
			draw_colored_polygon(_scaled([Vector2(0.24, 0.14), Vector2(0.5, 0.14),
				Vector2(0.34, 0.4), Vector2(0.02, 0.4)]), color.lightened(0.5))
		Kind.STAR:
			var points: Array = []
			for corner in 10:
				var reach := 0.48 if corner % 2 == 0 else 0.21
				var angle := -PI / 2.0 + corner * PI / 5.0
				points.append(Vector2(0.5, 0.53) + Vector2(cos(angle), sin(angle)) * reach)
			_fill(points)
		Kind.CHECK:
			_line([Vector2(0.14, 0.54), Vector2(0.4, 0.8), Vector2(0.86, 0.22)], stroke * 1.3)
		Kind.RESTART:
			draw_arc(Vector2(0.5, 0.52) * s, s * 0.32, -PI * 0.35, PI * 1.3, 24, color,
				stroke, true)
			_fill([Vector2(0.52, 0.0), Vector2(0.9, 0.24), Vector2(0.5, 0.42)])
		Kind.GEM:
			# A cut stone, long ways up, with one lighter facet.
			_fill([Vector2(0.5, 0.02), Vector2(0.86, 0.3), Vector2(0.86, 0.7),
				Vector2(0.5, 0.98), Vector2(0.14, 0.7), Vector2(0.14, 0.3)])
			draw_colored_polygon(_scaled([Vector2(0.5, 0.02), Vector2(0.5, 0.5),
				Vector2(0.14, 0.7), Vector2(0.14, 0.3)]), color.lightened(0.45))
		Kind.HOME:
			_fill([Vector2(0.5, 0.08), Vector2(0.94, 0.5), Vector2(0.06, 0.5)])
			draw_rect(Rect2(Vector2(0.2, 0.48) * s, Vector2(0.6, 0.4) * s), color)


## Both helpers take points in the unit square and scale them to the icon.
func _fill(points: Array) -> void:
	draw_colored_polygon(_scaled(points), color)


func _line(points: Array, width: float) -> void:
	draw_polyline(_scaled(points), color, width, true)


func _scaled(points: Array) -> PackedVector2Array:
	var s := minf(size.x, size.y)
	var out := PackedVector2Array()
	for point: Vector2 in points:
		out.append(point * s)
	return out
