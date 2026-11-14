class_name Enemy
extends Area3D
## A rival marble. Touching it sends the player back to their checkpoint,
## unless they land on it from above or are shielded, either of which pops it.
##
## It is an area, not a solid body, so what a touch *means* is decided by the
## game and not by a collision. Two behaviours: a patroller glides back and
## forth on a fixed line, and a chaser hunts the marble inside a leash.

signal touched(enemy: Enemy)

enum Mode { PATROL, CHASE }

const BODY_COLOR := Color(0.85, 0.16, 0.22)
const CHASER_COLOR := Color(0.7, 0.2, 0.85)
const RADIUS := 0.55

var mode: Mode = Mode.PATROL
## Patrol: offset to the far end of the line, and seconds there and back.
var travel := Vector3.ZERO
var period: float = 4.0
## Chase: how far from home it will go, and how fast.
var leash: float = 8.0
var speed: float = 4.5
## What a chaser hunts. Set by the game.
var target: Node3D = null
var defeated: bool = false

var _home := Vector3.ZERO
var _time: float = 0.0
var _body: Node3D


func _init(behaviour: Mode = Mode.PATROL) -> void:
	mode = behaviour
	collision_layer = 0
	collision_mask = 2
	var shape := SphereShape3D.new()
	shape.radius = RADIUS
	add_child(Mats.collider(shape, Vector3.UP * RADIUS))

	_body = Node3D.new()
	_body.position = Vector3.UP * RADIUS
	add_child(_body)
	# A rival marble: dark and glossy, with a glowing band round it so the
	# roll is visible. No face: it is a marble, like the player's.
	var color := BODY_COLOR if mode == Mode.PATROL else CHASER_COLOR
	var ball := SphereMesh.new()
	ball.radius = RADIUS
	ball.height = RADIUS * 2.0
	_body.add_child(Mats.mesh(ball, Mats.solid(Color(0.08, 0.07, 0.1), 0.15, 0.6)))
	var band := TorusMesh.new()
	band.inner_radius = RADIUS * 0.82
	band.outer_radius = RADIUS * 1.04
	var glow := Mats.glow(color, 2.0)
	for tilt: float in [0.0, PI / 2.0]:
		var stripe := Mats.mesh(band, glow)
		stripe.rotation.x = tilt
		stripe.scale.y = 0.5
		_body.add_child(stripe)
	body_entered.connect(_on_body_entered)


func _ready() -> void:
	_home = position


func _physics_process(delta: float) -> void:
	if defeated:
		return
	_time += delta
	if mode == Mode.PATROL:
		var cycle := _time / maxf(period, 0.1)
		var before := position
		position = _home + travel * (0.5 - 0.5 * cos(cycle * TAU))
		_roll(position - before)
		return
	var goal := _home
	if target != null:
		var offset := target.global_position - _home
		# Only gives chase while the marble is on its patch and near its level.
		if Vector2(offset.x, offset.z).length() < leash and absf(offset.y) < 2.5:
			goal = Vector3(target.global_position.x, _home.y, target.global_position.z)
	var step := (goal - position).limit_length(speed * delta)
	position += step
	_roll(step)


## Pops the guard. It stays gone for the rest of the attempt.
func defeat() -> void:
	if defeated:
		return
	defeated = true
	set_deferred(&"monitoring", false)
	var tween := create_tween()
	tween.tween_property(_body, ^"scale", Vector3(1.5, 0.2, 1.5), 0.08)
	tween.tween_property(_body, ^"scale", Vector3.ZERO, 0.15)
	tween.tween_callback(hide)


## Turns the ball as if it were rolling along [param motion].
func _roll(motion: Vector3) -> void:
	var flat := Vector3(motion.x, 0.0, motion.z)
	var distance := flat.length()
	if distance < 0.00001:
		return
	_body.rotate(Vector3.UP.cross(flat / distance), distance / RADIUS)
	_body.basis = _body.basis.orthonormalized()


func _on_body_entered(body: Node3D) -> void:
	if body is Marble and not defeated:
		touched.emit(self)
