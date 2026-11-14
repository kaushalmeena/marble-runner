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

@export_group("Rolling")
## Torque applied while a direction is held. Against the marble's inertia this
## is roughly 7 m/s² of rolling acceleration on a grippy floor.
@export var roll_torque: float = 5.0
## A direct push on top of the torque. Without it the marble feels like it is
## on rails made of treacle for the first half second.
@export var ground_push: float = 5.0
## The same push in the air, where torque does nothing. This is the air control.
@export var air_push: float = 6.0
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

var _coyote: float = 0.0
var _jump_buffer: float = 0.0
var _air_time: float = 0.0
var _ground_normal := Vector3.UP
var _previous_velocity := Vector3.ZERO
var _teleport_pending: bool = false
var _teleport_position := Vector3.ZERO

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
func teleport(world_position: Vector3) -> void:
	_teleport_position = world_position
	_teleport_pending = true


## Throws the marble straight up at [param speed], replacing any downward motion.
func launch(speed: float) -> void:
	var velocity := linear_velocity
	velocity.y = maxf(velocity.y, speed)
	linear_velocity = velocity


## Shoves the marble along [param direction] so it is travelling at least
## [param speed] that way.
func boost(direction: Vector3, speed: float) -> void:
	var heading := direction.normalized()
	var along := linear_velocity.dot(heading)
	if along < speed:
		linear_velocity += heading * (speed - along)


## Horizontal direction the player is holding, in world space, length 0..1.
func wish_direction() -> Vector3:
	var input := Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	return Basis(Vector3.UP, steer_yaw) * Vector3(input.x, 0.0, input.y)


func _physics_process(_delta: float) -> void:
	# Holding jump keeps the buffer topped up, so the marble hops again the
	# moment it lands instead of needing a press timed to the frame.
	if control_enabled and Input.is_action_pressed(&"jump"):
		_jump_buffer = jump_buffer_time


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if _teleport_pending:
		_teleport_pending = false
		state.transform = Transform3D(Basis.IDENTITY, _teleport_position)
		state.linear_velocity = Vector3.ZERO
		state.angular_velocity = Vector3.ZERO
		_previous_velocity = Vector3.ZERO
		return

	var step := state.step
	_read_ground(state)
	_previous_velocity = state.linear_velocity
	if not control_enabled:
		return
	_roll(state)
	_jump_buffer -= step
	if _jump_buffer > 0.0 and _coyote > 0.0:
		_jump(state)


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
		if not grounded and _air_time > MIN_AIR_TIME:
			landed.emit(maxf(0.0, -_previous_velocity.y))
		_air_time = 0.0
	else:
		_coyote -= state.step
		_air_time += state.step
	grounded = on_ground


## Looks up the shape being stood on and sets the marble's grip to match.
func _read_surface(state: PhysicsDirectBodyState3D, contact: int) -> void:
	var body := state.get_contact_collider_object(contact) as CollisionObject3D
	var icy := false
	if body != null:
		var owner_id := body.shape_find_owner(state.get_contact_collider_shape(contact))
		var shape := body.shape_owner_get_owner(owner_id) as Node
		icy = shape != null and shape.has_meta(META_ICE)
	if icy == on_ice:
		return
	on_ice = icy
	physics_material_override.friction = ICE_FRICTION if icy else GRIP_FRICTION


func _roll(state: PhysicsDirectBodyState3D) -> void:
	var wish := wish_direction()
	if wish.length_squared() < 0.0001:
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
		state.apply_central_force(wish * push)


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
