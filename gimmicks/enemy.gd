class_name Enemy
extends Area3D
## A spiky guard. Touching it sends the marble back to its checkpoint, unless
## the marble lands on it from above or is shielded, either of which pops it.
##
## It is an area, not a solid body, so what a touch *means* is decided by the
## game and not by a collision. Two behaviours: a patroller glides back and
## forth on a fixed line, and a chaser hunts the marble inside a leash.

signal touched(enemy: Enemy)

enum Mode { PATROL, CHASE }

const BODY_COLOR := Color(0.85, 0.16, 0.22)
const CHASER_COLOR := Color(0.7, 0.2, 0.85)
const RADIUS := 0.6

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
	var color := BODY_COLOR if mode == Mode.PATROL else CHASER_COLOR
	var ball := SphereMesh.new()
	ball.radius = RADIUS * 0.8
	ball.height = RADIUS * 1.6
	_body.add_child(Mats.mesh(ball, Mats.glow(color, 0.5)))
	# Spikes round the middle and one on top: the shape says "do not touch"
	# before the colour does.
	var spike := CylinderMesh.new()
	spike.top_radius = 0.0
	spike.bottom_radius = 0.14
	spike.height = 0.34
	spike.radial_segments = 6
	var steel := Mats.solid(Color(0.95, 0.95, 1.0), 0.3, 0.4)
	for index in 8:
		var angle := TAU * index / 8.0
		var thorn := Mats.mesh(spike, steel, Vector3(cos(angle), 0.0, sin(angle)) * RADIUS * 0.9)
		thorn.rotation = Vector3(0.0, -angle, -PI / 2.0)
		_body.add_child(thorn)
	# Eyes, so it has a front and looks like it is watching.
	var eye := SphereMesh.new()
	eye.radius = 0.11
	eye.height = 0.22
	for side: float in [-1.0, 1.0]:
		_body.add_child(Mats.mesh(eye, Mats.glow(Color.WHITE, 1.0),
			Vector3(side * 0.2, 0.14, -RADIUS * 0.7)))
	body_entered.connect(_on_body_entered)


func _ready() -> void:
	_home = position


func _physics_process(delta: float) -> void:
	if defeated:
		return
	_time += delta
	_body.position.y = RADIUS + sin(_time * 4.0) * 0.06
	if mode == Mode.PATROL:
		var cycle := _time / maxf(period, 0.1)
		var before := position
		position = _home + travel * (0.5 - 0.5 * cos(cycle * TAU))
		_face(position - before)
		return
	var goal := _home
	if target != null:
		var offset := target.global_position - _home
		# Only gives chase while the marble is on its patch and near its level.
		if Vector2(offset.x, offset.z).length() < leash and absf(offset.y) < 2.5:
			goal = Vector3(target.global_position.x, _home.y, target.global_position.z)
	var step := (goal - position).limit_length(speed * delta)
	position += step
	_face(step)


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


func _face(motion: Vector3) -> void:
	if Vector2(motion.x, motion.z).length_squared() > 0.000001:
		_body.rotation.y = atan2(-motion.x, -motion.z)


func _on_body_entered(body: Node3D) -> void:
	if body is Marble and not defeated:
		touched.emit(self)
