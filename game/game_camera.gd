class_name GameCamera
extends Camera3D
## Orbit camera that follows the marble.
##
## The view decides what "forward" means, so the camera owns the heading and
## hands it to the marble every frame. It can be turned with the keys or the
## mouse, and when left alone it drifts round behind the direction of travel so
## the game is fully playable without touching the camera at all.

@export_group("Orbit")
@export var distance: float = 6.5
@export var focus_height: float = 0.7
@export_range(-80.0, 10.0, 1.0, "radians_as_degrees") var pitch: float = deg_to_rad(-22.0)
## Radians per second while a camera key is held.
@export var key_turn_speed: float = 2.4
## Radians per pixel of mouse travel, before the sensitivity setting.
@export var mouse_turn_speed: float = 0.0035

@export_group("Auto follow")
## How eagerly the view swings behind the marble. Deliberately lazy: a camera
## that snaps to the velocity makes a sideways roll spiral.
@export var follow_rate: float = 1.5
## Seconds after a manual turn before auto follow resumes.
@export var manual_hold: float = 0.9
## Travel more than this far off the view axis is left alone, so rolling back
## toward the camera does not spin the world round.
@export_range(0.0, 180.0, 1.0, "radians_as_degrees") var follow_cone: float = deg_to_rad(110.0)

@export_group("Feel")
@export var base_fov: float = 70.0
@export var speed_fov: float = 14.0
@export var max_shake := Vector3(0.35, 0.25, 0.12)
@export var shake_decay: float = 2.6
@export var shake_frequency: float = 26.0

var yaw: float = 0.0
var target: Marble = null

var _focus := Vector3.ZERO
var _manual_cooldown: float = 0.0
var _trauma: float = 0.0
var _time: float = 0.0
var _noise := FastNoiseLite.new()


func _ready() -> void:
	# The camera is placed by hand every rendered frame from an already
	# interpolated target, so interpolating it again would only add lag.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.frequency = 1.0


## Starts following [param marble], looking along [param heading].
func follow(marble: Marble, heading: float) -> void:
	target = marble
	yaw = heading
	_focus = marble.global_position
	_place(0.0)


## Adds to the shake, clamped so repeated hits cannot stack into nausea.
func add_trauma(amount: float) -> void:
	if Settings.reduced_motion:
		return
	_trauma = clampf(_trauma + amount, 0.0, 1.0)


## Jumps the view to the target, for respawns.
func snap() -> void:
	if target != null:
		_focus = target.global_position


func _unhandled_input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion == null or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	var scale := mouse_turn_speed * Settings.mouse_sensitivity
	yaw -= motion.relative.x * scale
	pitch = clampf(pitch - motion.relative.y * scale, deg_to_rad(-75.0), deg_to_rad(5.0))
	_manual_cooldown = manual_hold


func _process(delta: float) -> void:
	if target == null:
		return
	_time += delta
	_trauma = maxf(0.0, _trauma - shake_decay * delta)

	var turn := Input.get_axis(&"camera_left", &"camera_right")
	if absf(turn) > 0.01:
		yaw -= turn * key_turn_speed * delta
		_manual_cooldown = manual_hold
	_manual_cooldown = maxf(0.0, _manual_cooldown - delta)
	_auto_follow(delta)

	var goal := target.get_global_transform_interpolated().origin
	_focus = _focus.lerp(goal, 1.0 - exp(-14.0 * delta))
	target.steer_yaw = yaw
	_place(delta)


func _auto_follow(delta: float) -> void:
	if not Settings.auto_camera or _manual_cooldown > 0.0:
		return
	var velocity := target.linear_velocity
	velocity.y = 0.0
	var speed := velocity.length()
	if speed < 2.5:
		return
	var heading := atan2(-velocity.x, -velocity.z)
	var difference := wrapf(heading - yaw, -PI, PI)
	if absf(difference) > follow_cone:
		return
	yaw += difference * minf(1.0, follow_rate * delta) * clampf(speed / 8.0, 0.0, 1.0)


func _place(delta: float) -> void:
	var orbit := Basis.from_euler(Vector3(pitch, yaw, 0.0))
	global_transform = Transform3D(
		orbit, _focus + Vector3.UP * focus_height + orbit.z * distance)

	var speed := target.linear_velocity.length()
	var wanted_fov := base_fov + speed_fov * clampf(speed / 22.0, 0.0, 1.0)
	fov = lerpf(fov, wanted_fov, clampf(4.0 * delta, 0.0, 1.0))

	if _trauma <= 0.0:
		return
	# Squared so the falloff is felt rather than linear.
	var shake := _trauma * _trauma
	var t := _time * shake_frequency
	translate_object_local(Vector3(
		max_shake.x * shake * _noise.get_noise_2d(t, 0.0),
		max_shake.y * shake * _noise.get_noise_2d(0.0, t),
		max_shake.z * shake * _noise.get_noise_2d(t, t)))
