class_name Marble
extends CharacterBody3D
## The player. Snaps between lanes and reports what it runs into.
##
## The marble no longer reaches out to the game scene for its lane layout (the
## Godot 3 version did [code]get_node("/root/Game")[/code], which broke the
## moment the scene was renamed or instanced somewhere else). The lanes are
## handed to it by whoever owns the run, via [method configure].

## The player touched an obstacle. The run is over.
signal hit_obstacle
## The player touched a fruit. Carries the prop so its owner can recycle it.
signal collected_pickup(pickup: Area3D)

const GROUP_OBSTACLE := &"obstacle"
const GROUP_COLLECTIBLE := &"collectible"
## Below this distance from the target lane, snap instead of easing forever.
const LANE_SNAP_EPSILON := 0.05

## How hard the marble is pulled toward its target lane.
@export var lane_change_speed: float = 14.0
## Caps the pull above, so a full-width dash does not look like a teleport.
@export var max_lateral_speed: float = 40.0
@export var gravity: float = 30.0
## Radius used to convert travel into spin. Match the mesh.
@export var roll_radius: float = 0.9

## Set each frame by the game so the marble spins at the speed of the world
## scrolling past it. The marble itself never moves along Z.
var forward_speed: float = 0.0

@onready var _hitbox: Area3D = $Hitbox
@onready var _mesh: MeshInstance3D = $Mesh

var _lanes: PackedFloat32Array = PackedFloat32Array()
var _lane_index: int = 0
var _active: bool = false


func _ready() -> void:
	_hitbox.area_entered.connect(_on_hitbox_area_entered)


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
	else:
		return
	get_viewport().set_input_as_handled()


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
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= gravity * delta


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
	elif area.is_in_group(GROUP_OBSTACLE):
		hit_obstacle.emit()
