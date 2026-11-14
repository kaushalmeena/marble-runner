class_name Marble
extends RigidBody3D
## The player: a physics marble that is rolled, not steered.
##
## Input never sets a velocity. It applies a torque, the marble spins, and
## friction with whatever it is standing on turns that spin into travel. That
## one decision is what makes ice slippery, ramps launch and bumpers bounce
## without any of those surfaces knowing about the marble.
##
## All of it happens in [method _integrate_forces], the one place a rigid body
## may be read and changed without fighting the solver.

## The marble pushed off the ground.
signal jumped
## The marble touched down after being airborne. [param impact] is the speed it
## was falling at, for the camera and the sound.
signal landed(impact: float)

const RADIUS := 0.5
## Metadata flag a collision shape carries to say it is ice.
const META_ICE := &"ice"
## The marble's own friction on ice and off it. Grip is changed on the marble
## rather than on the floor because one body holds every floor in the level.
const ICE_FRICTION := 0.02
const GRIP_FRICTION := 1.0
## Contact normals flatter than this are walls, not ground.
const GROUND_NORMAL_Y := 0.35
## Airborne for less than this is a bump over a seam, not a landing.
const MIN_AIR_TIME := 0.14
## How quickly an idle marble comes to rest on a moving platform, per second.
const PLATFORM_SETTLE := 14.0
## Grip assist on level ground. Left to friction alone a rolling ball coasts
## for ever and swings wide on every turn; these bleed off the motion the
## player is not asking for, which is what makes it feel held rather than
## loose. Per second: with nothing held, and across the held direction.
const COAST_BRAKE := 2.2
const SIDE_BRAKE := 3.0
## Extra push while steering against the way the marble is moving.
const REVERSE_PUSH := 1.8
## Ground flatter than this (normal Y) gets the assist. Slopes are left alone,
## so a marble still runs away downhill.
const LEVEL_NORMAL_Y := 0.96
## Share of the marble's weight that water carries. Under 1 so it still sinks.
const WATER_BUOYANCY := 0.8
## How quickly water bleeds off speed, per second.
const WATER_DRAG := 1.8
## Upward speed of one swimming stroke, and the gap between strokes.
const SWIM_SPEED := 5.0
const SWIM_INTERVAL := 0.28

@export_group("Rolling")
## Torque applied while a direction is held. Against the marble's inertia this
## is roughly 7 m/s² of rolling acceleration on a grippy floor.
@export var roll_torque: float = 5.0
## A direct push on top of the torque. Without it the marble feels like it is
## on rails made of treacle for the first half second.
@export var ground_push: float = 5.0
## The same push in the air, where torque does nothing. This is the air control.
@export var air_push: float = 8.0
## Input stops adding speed past this. Ramps, pads and gravity can still exceed it.
@export var max_speed: float = 13.0

@export_group("Jumping")
## Take-off speed. Against a gravity of 20 the apex is ~1.4 units, which is
## what every step and gap in the levels is measured against.
@export var jump_speed: float = 7.5
## Grace period after rolling off an edge in which a jump still counts.
@export var coyote_time: float = 0.12
## How long an early jump press is remembered before landing.
@export var jump_buffer_time: float = 0.14

## Hands the marble to the player. Off during the countdown and after the finish.
var control_enabled: bool = false
## Heading that "forward" maps to, in radians. Written by the camera each frame
## so the controls are always relative to the view.
var steer_yaw: float = 0.0
## True while something walkable is under the marble.
var grounded: bool = false
## True while the thing under the marble is ice.
var on_ice: bool = false
## Reverses the controls. Set while the dizzy ailment runs.
var steer_flipped: bool = false
## Ice grips like any floor, and tar and wind do nothing. Set by the grip
## power-up; the tar and the wind read it.
var sure_footed: bool = false
## Jumps allowed in mid-air before landing again. The double jump power-up
## sets this to one.
var air_jumps: int = 0:
	set(value):
		air_jumps = value
		# Granted at once, so spending the power-up in mid-air still counts.
		_air_jumps_left = value
## True while the marble is inside a body of water.
var in_water: bool:
	get:
		return _water_zones > 0

var _coyote: float = 0.0
var _jump_buffer: float = 0.0
var _air_time: float = 0.0
var _ground_normal := Vector3.UP
var _previous_velocity := Vector3.ZERO
## The moving platform under the marble, if any, and how fast it was going on
## the previous step.
var _platform: Mover = null
var _platform_velocity := Vector3.ZERO
var _teleport_pending: bool = false
var _teleport_position := Vector3.ZERO
var _teleport_velocity := Vector3.ZERO
var _air_jumps_left: int = 0
var _air_jump_pressed: bool = false
var _water_zones: int = 0
var _swim_cooldown: float = 0.0
var _bubble: MeshInstance3D = null

@onready var _mesh: MeshInstance3D = $Mesh


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	apply_skin(SkinLibrary.load_default().get_skin(GameState.selected_skin))


## Swaps the marble's look. Skins are cosmetic only.
func apply_skin(skin: MarbleSkin) -> void:
	if skin == null or skin.material == null:
		return
	_mesh.material_override = skin.material


## Moves the marble somewhere and brings it to rest. Used for the start and for
## respawns. Deferred to the next physics step, where it is safe.
## [param velocity] is what it arrives with: a portal passes its speed through.
func teleport(world_position: Vector3, velocity := Vector3.ZERO) -> void:
	_teleport_position = world_position
	_teleport_velocity = velocity
	_teleport_pending = true


## Called by a body of water as the marble crosses its surface.
func enter_water() -> void:
	_water_zones += 1


func exit_water() -> void:
	_water_zones = maxi(0, _water_zones - 1)


## Shows or hides the bubble that marks an active shield.
func set_shielded(active: bool) -> void:
	if _bubble == null:
		var shell := SphereMesh.new()
		shell.radius = RADIUS * 1.45
		shell.height = RADIUS * 2.9
		_bubble = Mats.mesh(shell, Mats.ghost(PowerUps.color(PowerUps.Kind.SHIELD), 0.3))
		_bubble.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_bubble)
	_bubble.visible = active


## Throws the marble straight up at [param speed], replacing any downward motion.
func launch(speed: float) -> void:
	var velocity := linear_velocity
	velocity.y = maxf(velocity.y, speed)
	linear_velocity = velocity


## Shoves the marble along [param direction] so it is travelling at least
## [param speed] that way.
## With [param align] the sideways motion is dropped too, so the marble leaves
## travelling exactly along [param direction] however it arrived.
func boost(direction: Vector3, speed: float, align: bool = false) -> void:
	var heading := direction.normalized()
	var along := linear_velocity.dot(heading)
	if align:
		linear_velocity = heading * maxf(along, speed) + Vector3.UP * linear_velocity.y
	elif along < speed:
		linear_velocity += heading * (speed - along)
	# Spin to match, or the marble arrives skidding and friction takes back
	# half of what the boost just gave.
	var flat := Vector3(linear_velocity.x, 0.0, linear_velocity.z)
	angular_velocity = Vector3.UP.cross(flat) / RADIUS


## Horizontal direction the player is holding, in world space, length 0..1.
func wish_direction() -> Vector3:
	var input := Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	if steer_flipped:
		input = -input
	return Basis(Vector3.UP, steer_yaw) * Vector3(input.x, 0.0, input.y)


func _physics_process(_delta: float) -> void:
	# Holding jump keeps the buffer topped up, so the marble hops again the
	# moment it lands instead of needing a press timed to the frame.
	if control_enabled and Input.is_action_pressed(&"jump"):
		_jump_buffer = jump_buffer_time
	# A mid-air jump needs a fresh press. Holding the key would spend it the
	# instant the marble left the ground.
	if control_enabled and Input.is_action_just_pressed(&"jump"):
		_air_jump_pressed = true


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if _teleport_pending:
		_teleport_pending = false
		state.transform = Transform3D(Basis.IDENTITY, _teleport_position)
		state.linear_velocity = _teleport_velocity
		var flat := Vector3(_teleport_velocity.x, 0.0, _teleport_velocity.z)
		state.angular_velocity = Vector3.UP.cross(flat) / RADIUS
		_previous_velocity = _teleport_velocity
		return

	var step := state.step
	_read_ground(state)
	_previous_velocity = state.linear_velocity
	if not control_enabled:
		return
	_roll(state)
	if in_water:
		_swim(state)
	_jump_buffer -= step
	if _jump_buffer > 0.0 and _coyote > 0.0:
		_jump(state)
	elif _air_jump_pressed and _air_jumps_left > 0 and _coyote <= 0.0 and not in_water:
		_air_jumps_left -= 1
		_jump(state)
	_air_jump_pressed = false


## Works out whether the marble is standing on something, from this step's
## contacts, and reports a landing when it has just come down.
func _read_ground(state: PhysicsDirectBodyState3D) -> void:
	var best := Vector3.ZERO
	var best_index := -1
	for index in state.get_contact_count():
		var normal := state.get_contact_local_normal(index)
		if normal.y > best.y:
			best = normal
			best_index = index
	var on_ground := best.y > GROUND_NORMAL_Y
	if on_ground:
		_read_surface(state, best_index)
	if on_ground:
		_ground_normal = best
		_coyote = coyote_time
		_air_jumps_left = air_jumps
		if not grounded and _air_time > MIN_AIR_TIME:
			landed.emit(maxf(0.0, -_previous_velocity.y))
		_air_time = 0.0
	else:
		_coyote -= state.step
		_air_time += state.step
		# A hop over a seam should not count as leaving the platform.
		if _air_time > MIN_AIR_TIME:
			_platform = null
	grounded = on_ground


## Looks up the shape being stood on and sets the marble's grip to match.
func _read_surface(state: PhysicsDirectBodyState3D, contact: int) -> void:
	var body := state.get_contact_collider_object(contact) as CollisionObject3D
	_ride(state, body as Mover)
	var icy := false
	if body != null:
		var owner_id := body.shape_find_owner(state.get_contact_collider_shape(contact))
		var shape := body.shape_owner_get_owner(owner_id) as Node
		icy = shape != null and shape.has_meta(META_ICE) and not sure_footed
	if icy == on_ice:
		return
	on_ice = icy
	physics_material_override.friction = ICE_FRICTION if icy else GRIP_FRICTION


## Carries the marble along with a moving platform.
##
## Friction alone only passes on two sevenths of a platform's acceleration to
## a ball free to roll: the rest goes into spin, and the marble is left behind
## as the platform pulls away. Handing it the remainder directly is what makes
## a platform something you can stand on.
func _ride(state: PhysicsDirectBodyState3D, platform: Mover) -> void:
	if platform != null and platform == _platform:
		var change := platform.velocity - _platform_velocity
		change.y = 0.0
		state.linear_velocity += change * (5.0 / 7.0)
	_platform = platform
	if platform != null:
		_platform_velocity = platform.velocity


func _roll(state: PhysicsDirectBodyState3D) -> void:
	var wish := wish_direction()
	_steady(state, wish)
	if wish.length_squared() < 0.0001:
		_settle_on_platform(state)
		return
	# Rolling toward `wish` is a spin about the axis at right angles to it.
	var axis := Vector3.UP.cross(wish)
	var spin := state.angular_velocity.dot(axis.normalized())
	# Capped so the marble cannot wind itself up without limit on ice or in the
	# air and then rocket away the moment it finds grip.
	if spin < max_speed / RADIUS * 1.25:
		state.apply_torque(axis * roll_torque)
	if state.linear_velocity.dot(wish.normalized()) < max_speed:
		# The direct push is the air control. On ice it is cut right down, or
		# it would steer the marble as if the ice were not there.
		var push := air_push if not grounded else (ground_push * 0.25 if on_ice else ground_push)
		if grounded and not on_ice and state.linear_velocity.dot(wish) < 0.0:
			push *= REVERSE_PUSH
		state.apply_central_force(wish * push)


## Sheds the motion the player is not asking for: all of it when nothing is
## held, the sideways part when a direction is. Only on level, grippy ground
## and at ordinary speeds, so ice stays ice, slopes stay slopes, and a marble
## flung by a pad keeps what it was given.
func _steady(state: PhysicsDirectBodyState3D, wish: Vector3) -> void:
	if not grounded or on_ice or in_water or _platform != null \
			or _ground_normal.y < LEVEL_NORMAL_Y:
		return
	var flat := Vector3(state.linear_velocity.x, 0.0, state.linear_velocity.z)
	if flat.length() > max_speed * 1.05:
		return
	var shed: Vector3
	if wish.length_squared() < 0.0001:
		shed = flat * minf(1.0, COAST_BRAKE * state.step)
	else:
		var along := wish.normalized()
		shed = (flat - along * flat.dot(along)) * minf(1.0, SIDE_BRAKE * state.step)
	state.linear_velocity -= shed
	# The spin that goes with that motion comes off too, or friction would
	# hand it straight back.
	state.angular_velocity -= Vector3.UP.cross(shed) / RADIUS


## With no direction held, a marble on a moving platform is eased to rest
## relative to it, so standing still on one actually means standing still.
func _settle_on_platform(state: PhysicsDirectBodyState3D) -> void:
	if _platform == null or not grounded:
		return
	var ease := minf(1.0, PLATFORM_SETTLE * state.step)
	var relative := state.linear_velocity - _platform.velocity
	relative.y = 0.0
	state.linear_velocity -= relative * ease
	state.angular_velocity -= state.angular_velocity * ease


## Water: most of the marble's weight is carried, speed bleeds away, and jump
## becomes a swimming stroke that works without anything to push off.
func _swim(state: PhysicsDirectBodyState3D) -> void:
	var weight := mass * gravity_scale * float(
		ProjectSettings.get_setting("physics/3d/default_gravity"))
	state.apply_central_force(Vector3.UP * weight * WATER_BUOYANCY)
	state.linear_velocity -= state.linear_velocity * minf(1.0, WATER_DRAG * state.step)
	_swim_cooldown -= state.step
	if _jump_buffer > 0.0 and _coyote <= 0.0 and _swim_cooldown <= 0.0:
		var velocity := state.linear_velocity
		velocity.y = maxf(velocity.y, SWIM_SPEED)
		state.linear_velocity = velocity
		_swim_cooldown = SWIM_INTERVAL
		_jump_buffer = 0.0


func _jump(state: PhysicsDirectBodyState3D) -> void:
	# Mostly up, but leaning with the slope, so a jump off a ramp carries the
	# ramp's angle with it.
	var normal := (_ground_normal + Vector3.UP).normalized() if grounded else Vector3.UP
	var velocity := state.linear_velocity
	var along := velocity.dot(normal)
	if along < jump_speed:
		velocity += normal * (jump_speed - along)
	state.linear_velocity = velocity
	_jump_buffer = 0.0
	_coyote = 0.0
	jumped.emit()


## Gimmicks that react to being touched (bumpers, crumbling tiles) expose
## [code]on_marble_hit[/code]. The marble does not know what any of them are.
func _on_body_entered(body: Node) -> void:
	if body.has_method(&"on_marble_hit"):
		body.on_marble_hit(self)
