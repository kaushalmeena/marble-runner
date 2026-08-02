class_name Marble
extends CharacterBody3D
## The player. Snaps between lanes and reports what it runs into.
##
## The marble no longer reaches out to the game scene for its lane layout (the
## Godot 3 version did [code]get_node("/root/Game")[/code], which broke the
## moment the scene was renamed or instanced somewhere else). The lanes are
## handed to it by whoever owns the run, via [method configure].

## The player touched an obstacle. Carries the prop so a shielded hit can
## recycle it instead of ending the run.
signal hit_obstacle(obstacle: Area3D)
## The player touched a fruit. Carries the prop so its owner can recycle it.
signal collected_pickup(pickup: Area3D)
## The player touched a power-up pickup.
signal collected_power_up(pickup: Area3D)
## The marble left the ground.
signal jumped
## The marble touched down again.
signal landed
## An obstacle slipped past without touching the marble.
signal near_missed

const GROUP_OBSTACLE := &"obstacle"
const GROUP_COLLECTIBLE := &"collectible"
const GROUP_POWERUP := &"powerup"
## Below this distance from the target lane, snap instead of easing forever.
const LANE_SNAP_EPSILON := 0.05

## How hard the marble is pulled toward its target lane.
@export var lane_change_speed: float = 14.0
## Caps the pull above, so a full-width dash does not look like a teleport.
@export var max_lateral_speed: float = 40.0
@export var gravity: float = 45.0
## Take-off speed. Together with [member gravity] this decides the apex, and the
## apex is what decides which obstacles are jumpable: at 9.6 against a gravity
## of 45 the marble rises ~1.02 units, which clears the one-unit rocks and logs
## but leaves the two-unit bushes and the trees solid.
@export var jump_velocity: float = 9.6
## Extra gravity while descending, so the fall does not feel floaty.
@export var fall_gravity_multiplier: float = 1.35
## Radius used to convert travel into spin. Match the mesh.
@export var roll_radius: float = 0.9

## Set each frame by the game so the marble spins at the speed of the world
## scrolling past it. The marble itself never moves along Z.
var forward_speed: float = 0.0

@onready var _hitbox: Area3D = $Hitbox
@onready var _near_miss_box: Area3D = $NearMissBox
@onready var _mesh: MeshInstance3D = $Mesh
@onready var _shield_bubble: MeshInstance3D = $ShieldBubble

var _lanes: PackedFloat32Array = PackedFloat32Array()
var _lane_index: int = 0
var _active: bool = false
var _airborne: bool = false


func _ready() -> void:
	_hitbox.area_entered.connect(_on_hitbox_area_entered)
	_near_miss_box.area_exited.connect(_on_near_miss_box_area_exited)
	_shield_bubble.hide()


## Shows or hides the bubble that marks an active shield.
func set_shielded(active: bool) -> void:
	_shield_bubble.visible = active


## Hands the marble its lane layout and drops it into a starting lane. Pass a
## negative [param start_index] to start in the middle lane.
func configure(lanes: PackedFloat32Array, start_index: int = -1) -> void:
	if lanes.is_empty():
		push_error("Marble.configure() needs at least one lane.")
		return
	_lanes = lanes
	_lane_index = start_index if start_index >= 0 else lanes.size() / 2
	_lane_index = clampi(_lane_index, 0, lanes.size() - 1)
	position.x = _lanes[_lane_index]


## Hands control to the player. Held back until the countdown finishes.
func begin() -> void:
	_active = true


## Stops input, motion and spin. Called when the run ends.
func stop() -> void:
	_active = false
	velocity = Vector3.ZERO
	forward_speed = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if event.is_action_pressed(&"move_left"):
		_change_lane(-1)
	elif event.is_action_pressed(&"move_right"):
		_change_lane(1)
	elif event.is_action_pressed(&"jump"):
		try_jump()
	else:
		return
	get_viewport().set_input_as_handled()


## Leaves the ground if the marble is on it. Returns whether it jumped, so a
## queued input can tell a refused jump from an accepted one.
func try_jump() -> bool:
	if not _active or not is_on_floor():
		return false
	velocity.y = jump_velocity
	_airborne = true
	jumped.emit()
	return true


func _physics_process(delta: float) -> void:
	if not _active:
		return
	var previous_x := position.x
	_apply_lane_motion()
	_apply_gravity(delta)
	move_and_slide()
	_apply_roll(position.x - previous_x, delta)


func _change_lane(step: int) -> void:
	_lane_index = clampi(_lane_index + step, 0, _lanes.size() - 1)


func _apply_lane_motion() -> void:
	var offset := _lanes[_lane_index] - position.x
	if absf(offset) < LANE_SNAP_EPSILON:
		position.x = _lanes[_lane_index]
		velocity.x = 0.0
		return
	velocity.x = clampf(offset * lane_change_speed, -max_lateral_speed, max_lateral_speed)


func _apply_gravity(delta: float) -> void:
	if is_on_floor() and velocity.y <= 0.0:
		if _airborne:
			_airborne = false
			landed.emit()
		velocity.y = 0.0
		return
	# Heavier on the way down than on the way up: the classic platformer trick
	# for a jump that feels responsive rather than floaty.
	var scale := fall_gravity_multiplier if velocity.y < 0.0 else 1.0
	velocity.y -= gravity * scale * delta


## Spins the mesh so the marble looks like it is rolling: forward spin from the
## world scrolling past, sideways spin from the lane change. Only the mesh turns,
## never the body, so the collision shape stays put.
func _apply_roll(lateral_distance: float, delta: float) -> void:
	if roll_radius <= 0.0:
		return
	_mesh.rotate_x(-forward_speed * delta / roll_radius)
	_mesh.rotate_z(-lateral_distance / roll_radius)
	# Repeated incremental rotations accumulate float error; keep the basis clean.
	_mesh.basis = _mesh.basis.orthonormalized()


func _on_hitbox_area_entered(area: Area3D) -> void:
	if not _active:
		return
	if area.is_in_group(GROUP_COLLECTIBLE):
		collected_pickup.emit(area)
	elif area.is_in_group(GROUP_POWERUP):
		collected_power_up.emit(area)
	elif area.is_in_group(GROUP_OBSTACLE):
		hit_obstacle.emit(area)


## An obstacle leaving the wider box counts as a near miss only if it left
## *behind* the marble. Anything recycled mid-run (a shielded hit, or a fruit
## the magnet grabbed) is parked far below and fails this test, so a hit can
## never be scored as a dodge.
func _on_near_miss_box_area_exited(area: Area3D) -> void:
	if not _active or not area.is_in_group(GROUP_OBSTACLE):
		return
	if area.global_position.z > global_position.z:
		near_missed.emit()
