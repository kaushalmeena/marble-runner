class_name Trail
extends RefCounted
## Lays a level out as a path, one stretch at a time.
##
## A long level written as raw [LevelBuilder] calls is a wall of coordinates,
## and one that turns corners is worse. A trail keeps a cursor: the middle of
## the path's leading edge, and which way it is heading. Each call builds the
## next stretch from there and moves the cursor to its far end, so a level
## reads as what happens in it: run, turn, gap, climb, glide.
##
## Everything is still placed through the builder; a level can mix the two.
##
## Each stretch also adds the waypoints a test bot follows to
## [member LevelBuilder.route]. That is how a sixty-stretch level gets run
## end to end without a hand-written route.

## Unit vectors for the four headings: 0 is -Z, and each step turns left.
const AHEAD: Array[Vector3] = [Vector3.FORWARD, Vector3.LEFT, Vector3.BACK, Vector3.RIGHT]
const SIDE: Array[Vector3] = [Vector3.RIGHT, Vector3.FORWARD, Vector3.LEFT, Vector3.BACK]
const LEFT := -1
const RIGHT := 1
const GRAVITY := 20.0

var b: LevelBuilder
## Middle of the path's leading edge, at floor height.
var at: Vector3
## Quarter turns to the left of -Z.
var heading: int = 0
## How wide an ordinary stretch of path is.
var width: float = 6.0
## The level's gravity, so a bounce pad is sized for the world it is in.
var gravity_scale: float = 1.0

## A floor laid after a step up is made this thick, so it reads as a ledge
## and not a slab hanging in the air.
var _thickness: float = 1.0
## Index in the route of the waypoint that closes the stretch just laid, or
## -1. A jump, a pad or a pickup that comes next wants it out of the way.
var _end_mark: int = -1


func _init(builder: LevelBuilder, from := Vector3.ZERO, quarter_turns: int = 0,
		path_width: float = 6.0) -> void:
	b = builder
	at = from
	heading = posmod(quarter_turns, 4)
	width = path_width
	# A trail that picks up where a hand-built stretch ends starts the bot on
	# the checkpoint placed there, which is certain to be standing on floor.
	b.route_start = from if b.checkpoints.is_empty() else b.checkpoints.back().position
	b.route_from_gem = b.gems.size()


## A point [param ahead] of the cursor, [param side] to its right and
## [param up] above the floor.
func pt(ahead: float = 0.0, side: float = 0.0, up: float = 0.0) -> Vector3:
	return at + AHEAD[heading] * ahead + SIDE[heading] * side + Vector3.UP * up


## Adds a waypoint for the test bot. See the bot harness for the flags.
func way(ahead: float, side: float = 0.0, flags: String = "") -> void:
	var point := pt(ahead, side)
	b.route.append("%.2f,%.2f,%s" % [point.x, point.z, flags])


## Marks the end of a stretch: a waypoint a little short of the cursor.
func _end(back: float = 1.0, flags: String = "") -> void:
	way(-back, 0.0, flags)
	_end_mark = b.route.size() - 1


## Takes back the end-of-stretch waypoint, for whatever needs a clean run at
## the edge: stopping a unit short of a gap is no way to jump it.
func _clear_end() -> void:
	if _end_mark >= 0 and _end_mark == b.route.size() - 1:
		b.route.remove_at(_end_mark)
	_end_mark = -1


## Adds a waypoint for something standing on the stretch just laid, visited
## before the end of that stretch rather than after it.
func _visit(ahead: float, side: float = 0.0) -> void:
	var point := pt(ahead, side)
	var entry := "%.2f,%.2f," % [point.x, point.z]
	if _end_mark >= 0 and _end_mark == b.route.size() - 1:
		b.route.insert(_end_mark, entry)
		_end_mark += 1
	else:
		b.route.append(entry)


# --- Start, finish and plain path ---------------------------------------------


## The starting pad, with the marble three units in from its near edge.
func start() -> void:
	var origin := at
	at = pt(-3.0)
	_slab(9.0)
	b.start(origin, heading * 90.0)
	b.route_start = origin


## The last pad, with the finish on it.
func finish() -> void:
	_slab(8.0, maxf(width, 8.0))
	b.finish_at(pt(-3.5))
	way(-3.5)


## A plain stretch [param length] long with [param gems] spaced along it.
func run(length: float, gems: int = 0, path_width: float = -1.0) -> void:
	for index in gems:
		var ahead := length * (index + 1.0) / (gems + 1.0)
		b.gem(pt(ahead))
		way(ahead)
	_slab(length, path_width)
	_end()


## A narrow stretch: one marble wide and not much more.
func beam(length: float, gems: int = 0, path_width: float = 2.0) -> void:
	var stops := maxi(gems, int(length / 5.0))
	for index in stops:
		var ahead := length * (index + 1.0) / (stops + 1.0)
		if index < gems:
			b.gem(pt(ahead))
		way(ahead, 0.0, "s6")
	_slab(length, path_width)
	_end(0.8, "s6")


## A square pad on which the path turns [constant LEFT] or [constant RIGHT].
func turn(direction: int) -> void:
	var centre := pt(width / 2.0)
	b.floor(centre.x, centre.z, width, width, at.y, LevelBuilder.Surface.FLOOR, _thickness)
	_thickness = 1.0
	way(width / 2.0)
	heading = posmod(heading - direction, 4)
	at = centre + AHEAD[heading] * width / 2.0


func checkpoint() -> void:
	b.checkpoint(pt(-1.5))
	_visit(-1.5)


func tip(text: String) -> void:
	b.tip(pt(-2.0), text)


# --- Going up, down and across ------------------------------------------------


## Nothing for [param length]: a jump. Up to 4 is a running jump; follow it
## with at least 3 of floor to land on.
func gap(length: float = 3.0) -> void:
	_clear_end()
	way(-4.0)
	way(-0.6, 0.0, "fs8")
	at = pt(length)
	way(2.2, 0.0, "j")


## The path carries on [param rise] higher: a ledge to jump onto.
func step(rise: float = 0.8) -> void:
	_clear_end()
	way(-4.0)
	way(-1.5, 0.0, "fs6")
	at.y += rise
	_thickness = rise + 1.0
	way(1.8, 0.0, "j")


## The path carries on [param fall] lower. Roll off.
func drop(fall: float) -> void:
	_clear_end()
	at.y -= fall
	way(2.0)


## A slope [param length] long that climbs [param rise] (or falls, if negative).
func ramp(length: float, rise: float) -> void:
	var top := pt(length, 0.0, rise)
	b.ramp(at, top, width)
	at = top
	way(0.6, 0.0, "h%.1f" % (at.y - 0.4))


## A bounce pad at the foot of a ledge [param rise] high.
func bounce(rise: float) -> void:
	_clear_end()
	b.bounce_pad(pt(-1.6), sqrt(2.0 * GRAVITY * gravity_scale * (rise + 1.3)))
	way(-3.2, 0.0, "s4")
	at.y += rise
	_thickness = rise + 1.0
	way(2.5, 0.0, "h%.1f" % (at.y - 0.3))


## A fan that lifts the marble to a ledge [param rise] higher.
func fan(rise: float) -> void:
	var spot := pt(3.0)
	_slab(6.0)
	b.fan(spot, 2.0 * (rise + 1.2))
	b.gem(spot + Vector3.UP * (rise * 0.6))
	b.route.append("%.2f,%.2f,ar1.4h%.1f" % [spot.x, spot.z, at.y + rise])
	at.y += rise
	way(2.2, 0.0, "h%.1f" % (at.y - 0.3))


## A glider, then a leap [param distance] across and [param fall] down.
## Follow it with at least 8 of floor. As a guide, from a running jump the
## glider carries about 15 plus one and a half for every unit of fall;
## without it the marble reaches about two thirds as far.
func glide(distance: float, fall: float) -> void:
	_clear_end()
	b.power_up(PowerUps.Kind.GLIDER, pt(-5.0))
	way(-5.0)
	way(-0.5, 0.0, "f")
	at = pt(distance, 0.0, -fall)
	way(3.0, 0.0, "j")


## A cannon that lobs the marble [param distance] on and [param rise] up.
## Follow it with at least 16 of floor: the marble lands fast.
func cannon(distance: float, rise: float = 0.0, flight: float = 2.2) -> void:
	var target := pt(distance, 0.0, rise)
	_clear_end()
	b.cannon(pt(-3.0), target, flight)
	way(-3.0, 0.0, "ar1.6")
	at = pt(distance - 4.0, 0.0, rise)
	way(4.0, 0.0, "car2.5")


## A platform that carries the marble across [param travel] of nothing.
func mover(travel: float, period: float = 8.0) -> void:
	_clear_end()
	way(-1.2)
	b.mover(pt(2.5), Vector2(5.0, 5.0), AHEAD[heading] * travel, period)
	way(2.5, 0.0, "MP")
	at = pt(5.0 + travel)
	way(1.5)


## A hard-light bridge [param length] long, and the button that builds it,
## on the floor just behind the cursor. With [param seconds] it is a race.
func bridge(length: float, seconds: float = 0.0, gems: int = 1) -> void:
	var centre := pt(length / 2.0)
	var across := heading % 2 == 0
	var span := b.bridge(centre.x, centre.z, 4.0 if across else length,
		length if across else 4.0, at.y)
	_clear_end()
	b.button(pt(-2.5), [span], seconds)
	way(-2.5)
	for index in gems:
		var ahead := length * (index + 1.0) / (gems + 1.0)
		b.gem(pt(ahead))
		way(ahead, 0.0, "far1.4")
	at = pt(length)
	way(1.8, 0.0, "ar1.4")


# --- Stretches with something in the way --------------------------------------


## [param count] tiles in a row that fall away soon after they are touched.
func crumbles(count: int, gems: bool = true) -> void:
	for index in count:
		var centre := pt(1.5 + index * 3.0)
		b.crumble(centre.x, centre.z, at.y)
		if gems and index % 2 == 0:
			b.gem(centre)
		way(1.5 + index * 3.0, 0.0, "far1.4")
	at = pt(count * 3.0)
	way(1.6, 0.0, "ar1.4")


## A stretch crossed by [param count] blinking beams, each lit a little after
## the one before it.
func lasers(count: int, spacing: float = 5.0, on_seconds: float = 1.2,
		off_seconds: float = 1.8) -> void:
	for index in count:
		var ahead := spacing * (index + 1.0)
		b.laser(pt(ahead, -width / 2.0), pt(ahead, width / 2.0), on_seconds, off_seconds,
			index * 0.6)
		b.gem(pt(ahead + spacing / 2.0))
		way(ahead + spacing / 2.0)
	_slab(spacing * (count + 1.0))
	_end()


## A belt. With [param against] it runs back toward the cursor.
func belt(length: float, against: bool = false, speed: float = 5.0) -> void:
	b.conveyor(pt(length / 2.0), Vector2(4.0, length),
		heading * 90.0 + (180.0 if against else 0.0), speed)
	b.gem(pt(length / 2.0))
	way(length / 2.0)
	_slab(length, 4.0)
	_end()


## Red blocks jutting in from alternate sides, to weave between.
func slalom(blocks: int, spacing: float = 5.0) -> void:
	var across := heading % 2 == 0
	var reach := width * 0.56
	for index in blocks:
		var ahead := spacing * (index + 1.0)
		var side := -1.0 if index % 2 == 0 else 1.0
		var centre := pt(ahead, side * (width - reach) / 2.0, 0.5)
		b.hazard(centre, Vector3(reach if across else 0.8, 1.0, 0.8 if across else reach))
		# Pass on the open side, and pick up the gem tucked behind the block.
		way(ahead - 0.4, -side * width * 0.3, "s7")
		way(ahead + 1.4, -side * width * 0.3, "s7")
		b.gem(pt(ahead + spacing / 2.0, side * width * 0.25))
		way(ahead + spacing / 2.0, side * width * 0.25, "s7")
	_slab(spacing * (blocks + 1.0))
	_end()


## A sheet of ice, with kerbs unless [param kerbs] is false.
func ice(length: float, gems: int = 0, kerbs: bool = true, path_width: float = -1.0) -> void:
	var wide := width if path_width < 0.0 else path_width
	if kerbs:
		for side: float in [-1.0, 1.0]:
			b.wall(pt(0.0, side * (wide / 2.0 + 0.2)), pt(length, side * (wide / 2.0 + 0.2)))
	for index in gems:
		var ahead := length * (index + 1.0) / (gems + 1.0)
		b.gem(pt(ahead))
		way(ahead, 0.0, "s6")
	_slab(length, wide, LevelBuilder.Surface.ICE)
	_end(1.0, "s5")


## A stretch of tar.
func mud(length: float, gems: int = 1) -> void:
	var centre := pt(length / 2.0)
	var across := heading % 2 == 0
	b.mud(centre.x, centre.z, width if across else length, length if across else width, at.y)
	run(length, gems)


## A stretch studded with bumpers, staggered left and right.
func bumpers(count: int, spacing: float = 4.0) -> void:
	for index in count:
		var side := -1.0 if index % 2 == 0 else 1.0
		b.bumper(pt(spacing * (index + 1.0), side * width * 0.2))
		b.gem(pt(spacing * (index + 1.0), -side * width * 0.28))
		way(spacing * (index + 1.0), -side * width * 0.28, "s7")
	_slab(spacing * (count + 1.0))
	_end()


## An open square with a ring of gems, and [param guards] chasers in it.
func arena(size: float = 14.0, gems: int = 6, guards: int = 0) -> void:
	var centre := pt(size / 2.0)
	b.floor(centre.x, centre.z, size, size, at.y, LevelBuilder.Surface.FLOOR, _thickness)
	_thickness = 1.0
	var radius := size * 0.32
	b.gem_ring(centre, radius, gems)
	for index in gems:
		var angle := TAU * index / gems
		b.route.append("%.2f,%.2f," % [
			centre.x + sin(angle) * radius, centre.z + cos(angle) * radius])
	for index in guards:
		var offset := Vector3.ZERO if guards == 1 else \
			SIDE[heading] * (size * 0.2) * (1.0 if index % 2 == 0 else -1.0)
		b.chaser(centre + offset, size * 0.45, 3.6)
	at = pt(size)
	_end()


# --- Things placed on the stretch just laid -----------------------------------


## A power-up a little behind the cursor.
func power(kind: PowerUps.Kind, side: float = 0.0) -> void:
	b.power_up(kind, pt(-2.5, side))
	_visit(-2.5, side)


## A trap [param back] behind the cursor. The bot does not go near it.
func trap(kind: PowerUps.Kind, side: float = 0.0, back: float = 3.0) -> void:
	b.trap(kind, pt(-back, side))


## A rival rolling from side to side across the path, [param back] behind.
func patrol(back: float = 3.0, period: float = 3.6) -> void:
	b.patroller(pt(-back, -width / 2.0 + 0.8), SIDE[heading] * (width - 1.6), period)


func sentry(side: float = 0.0, back: float = 3.0, reach: float = 10.0) -> void:
	b.sentry(pt(-back, side), reach)


func key(side: float = 0.0) -> void:
	b.key(pt(-2.5, side))
	_visit(-2.5, side)


## A gate across the end of the stretch just laid.
func gate() -> void:
	b.gate(pt(-0.6), width, heading * 90.0)


# --- Internals ----------------------------------------------------------------


## Lays floor from the cursor for [param length] and moves the cursor on.
func _slab(length: float, path_width: float = -1.0,
		surface: LevelBuilder.Surface = LevelBuilder.Surface.FLOOR) -> void:
	var wide := width if path_width < 0.0 else path_width
	var centre := pt(length / 2.0)
	var across := heading % 2 == 0
	b.floor(centre.x, centre.z, wide if across else length, length if across else wide,
		at.y, surface, _thickness)
	_thickness = 1.0
	at = pt(length)
