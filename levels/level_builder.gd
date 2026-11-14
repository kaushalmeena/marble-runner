class_name LevelBuilder
extends RefCounted
## Turns a level's build calls into nodes.
##
## Everything a level places goes through here, which is what keeps level
## scripts short: they say [code]b.floor(...)[/code] and never touch a mesh, a
## collision shape or a material.
##
## Conventions the level scripts rely on:
## - Forward is -Z. A level starts at the origin and heads away from the camera.
## - A position handed to a gimmick is the point on the floor it stands on.
## - [method floor] takes the height of the walkable top, not the box centre.

enum Surface {
	## The biome's checkerboard. Full grip.
	FLOOR,
	## Kerbs, cliffs and pillars. A second colour so edges read.
	WALL,
	## Almost no grip: the marble keeps whatever speed it arrives with.
	ICE,
}

const SHADER := preload("res://world/surface.gdshader")
const ICE_COLOR := Color(0.72, 0.9, 1.0)
const HAZARD_COLOR := Color(1.0, 0.2, 0.2)
const PORTAL_COLORS: Array[Color] = [
	Color(0.3, 0.8, 1.0), Color(1.0, 0.6, 0.2), Color(0.75, 0.45, 1.0)]

var root: Node3D
var start_position := Vector3(0.0, 1.0, 0.0)
## Heading the camera starts on, in radians.
var start_yaw: float = 0.0
var finish: FinishPad = null
var gems: Array[Gem] = []
var pickups: Array[PowerUpPickup] = []
var checkpoints: Array[Checkpoint] = []
var tips: Array[TriggerZone] = []
var hazards: Array[TriggerZone] = []
var enemies: Array[Enemy] = []
var portals: Array[Portal] = []
var keys: Array[GateKey] = []
var gates: Array[Gate] = []
var cannons: Array[Cannon] = []
## True once any water has been placed, for the HUD's level conditions.
var has_water: bool = false
## The line a test bot follows through the level, as "x,z,flags" waypoints,
## written by [Trail] as it lays the path. Nothing in the game reads it.
var route := PackedStringArray()
## Where that line begins, and how many gems were placed before it, for
## levels whose first stretch was laid out by hand.
var route_start := Vector3.ZERO
var route_from_gem: int = 0
## Bounds of everything solid, for the fall limit and the scenery.
var bounds := AABB()

var _biome: Biome
var _materials: Dictionary[int, ShaderMaterial] = {}
var _moving_material: ShaderMaterial
var _grip: PhysicsMaterial
var _has_bounds: bool = false
## Every fixed box in the level is a shape on this one body. The physics engine
## only smooths over the seam between two boxes when they belong to the same
## body; as separate bodies, a marble crossing from one floor to the next at
## speed catches the hidden edge and is kicked into the air.
var _static := StaticBody3D.new()


func _init(parent: Node3D, biome: Biome) -> void:
	root = parent
	_biome = biome
	root.add_child(_static)
	_materials[Surface.FLOOR] = _surface_material(
		biome.ground_color.darkened(0.12), biome.ground_color.lightened(0.06),
		biome.ground_color.darkened(0.55))
	_materials[Surface.WALL] = _surface_material(
		biome.rock_color, biome.rock_color.lightened(0.1), biome.rock_color.darkened(0.35))
	_materials[Surface.ICE] = _surface_material(
		ICE_COLOR, ICE_COLOR.lightened(0.35), ICE_COLOR.darkened(0.3), 0.08, 0.3)
	_moving_material = _surface_material(
		biome.foliage_color.lightened(0.15), biome.foliage_color.lightened(0.35),
		biome.foliage_color.darkened(0.4))
	_moving_material.set_shader_parameter(&"local_space", true)
	_grip = PhysicsMaterial.new()
	_grip.friction = 1.0
	_static.physics_material_override = _grip


## Height below which the marble is considered lost.
func fall_limit() -> float:
	return bounds.position.y - 12.0


# --- Solid geometry ---------------------------------------------------------


## A solid box, by centre and size. Everything fixed is built on this. The
## returned node can be turned or moved further by the caller.
func box(center: Vector3, size: Vector3, surface: Surface = Surface.FLOOR,
		yaw_degrees: float = 0.0) -> Node3D:
	var node := _fill_box(_static, size, _materials[surface])
	node.position = center
	node.rotation.y = deg_to_rad(yaw_degrees)
	if surface == Surface.ICE:
		node.set_meta(Marble.META_ICE, true)
	_grow_bounds(center, size)
	return node


## A slab whose walkable top is at height [param y], centred on ([param x],
## [param z]) and [param width] by [param depth].
func floor(x: float, z: float, width: float, depth: float, y: float = 0.0,
		surface: Surface = Surface.FLOOR, thickness: float = 1.0) -> Node3D:
	return box(Vector3(x, y - thickness / 2.0, z), Vector3(width, thickness, depth), surface)


## A slope whose surface runs from [param from] to [param to], both on the
## centre line of the walkable top.
func ramp(from: Vector3, to: Vector3, width: float,
		surface: Surface = Surface.FLOOR, thickness: float = 0.5) -> Node3D:
	var run := to - from
	var node := _fill_box(_static, Vector3(width, thickness, run.length()), _materials[surface])
	node.basis = Basis.looking_at(run.normalized(), Vector3.UP)
	node.position = (from + to) / 2.0 - node.basis.y * thickness / 2.0
	_grow_bounds((from + to) / 2.0, Vector3(width, absf(run.y) + thickness, width).max(run.abs()))
	return node


## A launch ramp that starts flat and steepens toward [param to]. A straight
## ramp meets the floor at a kink, and a fast marble hits that kink like a
## wall; easing into the slope keeps the speed the ramp is there to use.
func curved_ramp(from: Vector3, to: Vector3, width: float, segments: int = 5) -> void:
	var previous := from
	for index in range(1, segments + 1):
		var t := float(index) / segments
		var point := from.lerp(to, t)
		point.y = from.y + (to.y - from.y) * t * t
		ramp(previous, point, width)
		previous = point


## A kerb along the floor from [param from] to [param to].
func wall(from: Vector3, to: Vector3, height: float = 0.7, thickness: float = 0.4) -> Node3D:
	var run := to - from
	var body := box((from + to) / 2.0 + Vector3.UP * height / 2.0,
		Vector3(thickness, height, run.length() + thickness), Surface.WALL)
	body.rotation.y = atan2(run.x, run.z)
	return body


## A platform that glides between its starting point and [param travel] away
## from it. [param top] is the centre of its walkable surface.
func mover(top: Vector3, size: Vector2, travel: Vector3, period: float = 8.0,
		phase: float = 0.0) -> Mover:
	var body := Mover.new()
	body.travel = travel
	body.period = period
	body.phase = phase
	body.physics_material_override = _grip
	var extent := Vector3(size.x, 0.5, size.y)
	_fill_box(body, extent, _moving_material)
	body.position = top - Vector3.UP * 0.25
	root.add_child(body)
	_grow_bounds(body.position, extent)
	_grow_bounds(body.position + travel, extent)
	return body


## A tile that falls away shortly after it is touched.
func crumble(x: float, z: float, y: float = 0.0, yaw_degrees: float = 0.0,
		size := Vector2(3.0, 3.0)) -> CrumbleTile:
	var extent := Vector3(size.x, 0.5, size.y)
	var tile := CrumbleTile.new(extent)
	tile.physics_material_override = _grip
	tile.position = Vector3(x, y - 0.25, z)
	tile.rotation.y = deg_to_rad(yaw_degrees)
	root.add_child(tile)
	_grow_bounds(tile.position, extent)
	return tile


# --- Start, goal and collectibles -------------------------------------------


## Where the marble begins. [param yaw_degrees] turns the opening view; zero
## looks down -Z.
func start(at: Vector3, yaw_degrees: float = 0.0) -> void:
	start_position = at + Vector3.UP * (Marble.RADIUS + 0.3)
	start_yaw = deg_to_rad(yaw_degrees)
	var disc := CylinderMesh.new()
	disc.top_radius = 1.3
	disc.bottom_radius = 1.3
	disc.height = 0.06
	_place(Mats.mesh(disc, Mats.glow(Color(0.35, 0.7, 1.0), 0.8)), at + Vector3.UP * 0.03)


func finish_at(at: Vector3) -> FinishPad:
	finish = FinishPad.new()
	_place(finish, at)
	return finish


func gem(at: Vector3) -> Gem:
	var node := Gem.new(gems.size())
	_place(node, at)
	gems.append(node)
	return node


## [param count] gems evenly spaced from [param from] to [param to] inclusive.
func gem_line(from: Vector3, to: Vector3, count: int) -> void:
	for index in count:
		gem(from.lerp(to, float(index) / maxf(1.0, count - 1.0)))


## [param count] gems in a circle on the floor.
func gem_ring(center: Vector3, radius: float, count: int) -> void:
	for index in count:
		var angle := TAU * index / count
		gem(center + Vector3(sin(angle), 0.0, cos(angle)) * radius)


func checkpoint(at: Vector3) -> Checkpoint:
	var node := Checkpoint.new()
	_place(node, at)
	checkpoints.append(node)
	return node


func power_up(kind: PowerUps.Kind, at: Vector3) -> PowerUpPickup:
	var node := PowerUpPickup.new(kind)
	_place(node, at)
	pickups.append(node)
	return node


# --- Gimmicks ---------------------------------------------------------------


## A strip that flings the marble. Zero [param yaw_degrees] fires down -Z, and
## positive turns it anticlockwise seen from above, so 90 fires down -X.
func boost_pad(at: Vector3, yaw_degrees: float = 0.0, speed: float = 20.0) -> BoostPad:
	var pad := BoostPad.new(speed)
	_place(pad, at)
	pad.rotation.y = deg_to_rad(yaw_degrees)
	return pad


func bounce_pad(at: Vector3, speed: float = 14.0) -> BouncePad:
	var pad := BouncePad.new(speed)
	_place(pad, at)
	return pad


func bumper(at: Vector3, strength: float = 11.0) -> Bumper:
	var post := Bumper.new(strength)
	_place(post, at)
	return post


## A bar sweeping round [param at]. [param length] is tip to tip.
func spinner(at: Vector3, length: float = 8.0, speed: float = 1.4) -> Spinner:
	var bar := Spinner.new(length, speed)
	_place(bar, at)
	return bar


## A column of rising air standing on [param at]. The marble hovers halfway up.
func fan(at: Vector3, height: float = 12.0, radius: float = 2.2) -> Fan:
	var column := Fan.new(height, radius)
	_place(column, at)
	return column


## A guard gliding back and forth between [param at] and [param travel] away.
func patroller(at: Vector3, travel: Vector3, period: float = 4.0) -> Enemy:
	var guard := Enemy.new(Enemy.Mode.PATROL)
	guard.travel = travel
	guard.period = period
	_place(guard, at)
	enemies.append(guard)
	return guard


## A guard that hunts the marble while it is within [param leash] of [param at].
func chaser(at: Vector3, leash: float = 8.0, speed: float = 4.5) -> Enemy:
	var guard := Enemy.new(Enemy.Mode.CHASE)
	guard.leash = leash
	guard.speed = speed
	_place(guard, at)
	enemies.append(guard)
	return guard


## Two linked doors. Each yaw is the way the marble is thrown *out* of that
## door: zero is down -Z, 90 is down -X.
func portal_pair(first: Vector3, first_yaw: float, second: Vector3, second_yaw: float) -> void:
	var color := PORTAL_COLORS[(portals.size() / 2) % PORTAL_COLORS.size()]
	var a := Portal.new(color)
	var b := Portal.new(color)
	_place(a, first)
	_place(b, second)
	a.rotation.y = deg_to_rad(first_yaw)
	b.rotation.y = deg_to_rad(second_yaw)
	a.partner = b
	b.partner = a
	portals.append(a)
	portals.append(b)


func key(at: Vector3) -> GateKey:
	var node := GateKey.new()
	_place(node, at)
	keys.append(node)
	return node


## A barred gate across the path, [param width] wide. Opens for one key.
func gate(at: Vector3, width: float = 4.0, yaw_degrees: float = 0.0) -> Gate:
	var node := Gate.new(width)
	_place(node, at)
	node.rotation.y = deg_to_rad(yaw_degrees)
	gates.append(node)
	return node


## A guard that stays where it is and fires slow shots at a marble within
## [param reach].
func sentry(at: Vector3, reach: float = 12.0, period: float = 2.2) -> Enemy:
	var guard := Enemy.new(Enemy.Mode.SENTRY)
	guard.leash = reach
	guard.fire_period = period
	_place(guard, at)
	enemies.append(guard)
	return guard


## A trap: a pickup that does the marble harm for a few seconds. [param kind]
## is one of [constant PowerUps.AILMENTS].
func trap(kind: PowerUps.Kind, at: Vector3) -> PowerUpPickup:
	return power_up(kind, at)


## A belt [param size] wide and long that carries the marble. Zero
## [param yaw_degrees] runs down -Z; 90 runs down -X.
func conveyor(at: Vector3, size := Vector2(3.0, 8.0), yaw_degrees: float = 0.0,
		speed: float = 5.0) -> Conveyor:
	var belt := Conveyor.new(size, speed)
	_place(belt, at)
	belt.rotation.y = deg_to_rad(yaw_degrees)
	return belt


## A patch of tar on the floor at height [param y].
func mud(x: float, z: float, width: float, depth: float, y: float = 0.0) -> Mud:
	var patch := Mud.new(Vector2(width, depth))
	_place(patch, Vector3(x, y, z))
	return patch


## A beam across the floor from [param from] to [param to] that is lit for
## [param on_seconds] and dark for [param off_seconds], starting [param phase]
## seconds into that cycle.
func laser(from: Vector3, to: Vector3, on_seconds: float = 1.5, off_seconds: float = 1.5,
		phase: float = 0.0) -> Laser:
	var run := to - from
	var beam := Laser.new(run.length(), on_seconds, off_seconds, phase)
	_place(beam, (from + to) / 2.0)
	beam.rotation.y = atan2(run.x, run.z)
	hazards.append(beam)
	return beam


## A slab of hard light whose walkable top is at [param y]. It is only solid
## while a [method button] wired to it is down.
func bridge(x: float, z: float, width: float, depth: float, y: float = 0.0) -> Bridge:
	var extent := Vector3(width, 0.4, depth)
	var slab := Bridge.new(extent)
	slab.physics_material_override = _grip
	_place(slab, Vector3(x, y - 0.2, z))
	_grow_bounds(slab.position, extent)
	return slab


## A floor button wired to [param targets] (bridges, lasers). It stays down
## for [param seconds], or for good at zero.
func button(at: Vector3, targets: Array, seconds: float = 0.0) -> FloorButton:
	var pad := FloorButton.new(seconds)
	pad.targets = targets
	_place(pad, at)
	return pad


## A cannon standing on [param at] that lobs the marble onto [param target],
## taking [param flight] seconds to get there.
func cannon(at: Vector3, target: Vector3, flight: float = 1.6) -> Cannon:
	var gun := Cannon.new(target - at, flight)
	_place(gun, at)
	cannons.append(gun)
	return gun


## A box of water, by centre and size. Its top face is the surface.
func water(center: Vector3, size: Vector3) -> WaterZone:
	var pool := WaterZone.new(size)
	has_water = true
	_place(pool, center)
	return pool


## A glowing red block that sends the marble back to its checkpoint.
func hazard(center: Vector3, size: Vector3) -> TriggerZone:
	var shape := BoxShape3D.new()
	shape.size = size
	var zone := TriggerZone.new(shape)
	zone.one_shot = false
	var block := BoxMesh.new()
	block.size = size
	zone.add_child(Mats.mesh(block, Mats.glow(HAZARD_COLOR, 2.0)))
	_place(zone, center)
	hazards.append(zone)
	return zone


## A line of text shown when the marble gets within [param radius] of
## [param at].
func tip(at: Vector3, text: String, radius: float = 3.0) -> TriggerZone:
	var shape := SphereShape3D.new()
	shape.radius = radius
	var zone := TriggerZone.new(shape, text)
	_place(zone, at + Vector3.UP)
	tips.append(zone)
	return zone


# --- Internals --------------------------------------------------------------


func _place(node: Node3D, at: Vector3) -> void:
	node.position = at
	root.add_child(node)


## Adds a box shape, with its mesh, to [param body]. Returns the shape node.
func _fill_box(body: Node3D, size: Vector3, material: Material) -> CollisionShape3D:
	var shape := BoxShape3D.new()
	shape.size = size
	var node := Mats.collider(shape)
	var mesh := BoxMesh.new()
	mesh.size = size
	node.add_child(Mats.mesh(mesh, material))
	body.add_child(node)
	return node


func _grow_bounds(center: Vector3, size: Vector3) -> void:
	var extent := AABB(center - size / 2.0, size)
	bounds = extent if not _has_bounds else bounds.merge(extent)
	_has_bounds = true


func _surface_material(color_a: Color, color_b: Color, side: Color,
		roughness: float = 0.78, metallic: float = 0.0) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter(&"color_a", color_a)
	material.set_shader_parameter(&"color_b", color_b)
	material.set_shader_parameter(&"side_color", side)
	material.set_shader_parameter(&"roughness_value", roughness)
	material.set_shader_parameter(&"metallic_value", metallic)
	return material
