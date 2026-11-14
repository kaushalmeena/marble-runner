class_name Enemy
extends Area3D
## A rival marble. Touching it sends the player back to their checkpoint,
## unless they land on it from above or are shielded, either of which pops it.
##
## It is an area, not a solid body, so what a touch *means* is decided by the
## game and not by a collision. Two behaviours: a patroller glides back and
## forth on a fixed line, a chaser hunts the marble inside a leash, and a
## sentry stays put and fires slow shots at a marble that comes in range.

signal touched(enemy: Enemy)
## One of a sentry's shots reached the marble.
signal shot_struck

enum Mode { PATROL, CHASE, SENTRY }


## A sentry's shot: a glowing ball that flies straight and fades out.
class Shot extends Area3D:
	signal struck

	var velocity := Vector3.ZERO
	var life: float = 2.0

	func _init(color: Color) -> void:
		collision_layer = 0
		collision_mask = 2
		var shape := SphereShape3D.new()
		shape.radius = 0.28
		add_child(Mats.collider(shape))
		var ball := SphereMesh.new()
		ball.radius = 0.24
		ball.height = 0.48
		add_child(Mats.mesh(ball, Mats.glow(color, 3.0)))
		body_entered.connect(_on_body_entered)

	func _physics_process(delta: float) -> void:
		position += velocity * delta
		life -= delta
		if life <= 0.0:
			queue_free()

	func _on_body_entered(body: Node3D) -> void:
		if body is Marble:
			struck.emit()
			queue_free()


const BODY_COLOR := Color(0.85, 0.16, 0.22)
const CHASER_COLOR := Color(0.7, 0.2, 0.85)
const SENTRY_COLOR := Color(1.0, 0.6, 0.12)
const SHOT_SPEED := 7.0
const RADIUS := 0.55

var mode: Mode = Mode.PATROL
## Patrol: offset to the far end of the line, and seconds there and back.
var travel := Vector3.ZERO
var period: float = 4.0
## Chase: how far from home it will go, and how fast.
var leash: float = 8.0
var speed: float = 4.5
## Sentry: seconds between shots. [member leash] is its range.
var fire_period: float = 2.2
## What a chaser hunts. Set by the game.
var target: Node3D = null
var defeated: bool = false
## Things brought out when this rival is popped: a concealed secret diamond.
var reveals: Array = []

var _home := Vector3.ZERO
var _time: float = 0.0
var _body: Node3D
var _cooldown: float = 0.8


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
	var color: Color = [BODY_COLOR, CHASER_COLOR, SENTRY_COLOR][mode]
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
	if mode == Mode.SENTRY:
		# A stubby barrel, so it is plain which way the next shot is going.
		var tube := CylinderMesh.new()
		tube.top_radius = 0.16
		tube.bottom_radius = 0.2
		tube.height = 0.5
		var barrel := Mats.mesh(tube, glow, Vector3.FORWARD * (RADIUS + 0.15))
		barrel.rotation.x = -PI / 2.0
		_body.add_child(barrel)
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
	if mode == Mode.SENTRY:
		_watch(delta)
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


## A sentry turns to face a marble in range and fires on a timer. Out of
## range it winds back to a short fuse, so the first shot comes soon after the
## marble shows itself but never the instant it does.
func _watch(delta: float) -> void:
	if target == null:
		return
	var muzzle := global_position + Vector3.UP * RADIUS
	var offset := target.global_position - muzzle
	if offset.length() > leash:
		_cooldown = minf(_cooldown + delta, 0.8)
		return
	_body.look_at(muzzle + Vector3(offset.x, 0.0, offset.z) + Vector3.FORWARD * 0.001)
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	_cooldown = fire_period
	var shot := Shot.new(SENTRY_COLOR)
	shot.velocity = offset.normalized() * SHOT_SPEED
	shot.life = leash * 1.25 / SHOT_SPEED
	shot.struck.connect(shot_struck.emit)
	get_parent().add_child(shot)
	shot.global_position = muzzle
	Audio.play(&"bumper", -12.0, 0.05, 1.7)


## Pops the guard. It stays gone for the rest of the attempt.
func defeat() -> void:
	if defeated:
		return
	defeated = true
	set_deferred(&"monitoring", false)
	for target: Object in reveals:
		target.switch_to(true)
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
