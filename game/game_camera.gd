class_name GameCamera
extends Camera3D
## Chase camera with trauma-based shake.
##
## Callers add trauma rather than triggering a shake directly, so overlapping
## events accumulate into one motion instead of fighting each other. Shake
## strength is trauma squared, which keeps small knocks subtle while still
## letting a crash hit hard.

@export var max_offset := Vector3(0.5, 0.32, 0.18)
@export_range(0.0, 0.2, 0.005) var max_roll: float = 0.045
## Trauma lost per second. Higher is a snappier recovery.
@export var decay: float = 2.4
## How fast the shake oscillates.
@export var frequency: float = 26.0

## How much of the road's sideways offset the camera follows. Full follow would
## swing the marble across the screen; a fraction reads as leaning into a turn.
@export_range(0.0, 1.0, 0.05) var lean_fraction: float = 0.35
## How quickly the lean catches up, so it eases rather than snaps.
@export var lean_response: float = 3.0

var _trauma: float = 0.0
var _lean: float = 0.0
var _lean_target: float = 0.0
var _time: float = 0.0
var _rest_transform: Transform3D
var _noise := FastNoiseLite.new()


func _ready() -> void:
	_rest_transform = transform
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.frequency = 1.0


## Adds to the shake, clamped so repeated hits cannot stack into nausea.
func add_trauma(amount: float) -> void:
	if Settings.reduced_motion:
		return
	_trauma = clampf(_trauma + amount, 0.0, 1.0)


## Sets how far the road has bent away ahead of the player.
func set_road_offset(offset: float) -> void:
	_lean_target = offset * lean_fraction


func _process(delta: float) -> void:
	_time += delta
	_lean = lerpf(_lean, _lean_target, clampf(lean_response * delta, 0.0, 1.0))
	_trauma = maxf(0.0, _trauma - decay * delta)

	transform = _rest_transform
	position.x += _lean
	if _trauma <= 0.0:
		return
	# Squared so the falloff is felt rather than linear.
	var shake := _trauma * _trauma
	var t := _time * frequency
	translate_object_local(Vector3(
		max_offset.x * shake * _noise.get_noise_2d(t, 0.0),
		max_offset.y * shake * _noise.get_noise_2d(0.0, t),
		max_offset.z * shake * _noise.get_noise_2d(t, t)
	))
	rotate_object_local(Vector3.BACK, max_roll * shake * _noise.get_noise_2d(t, 512.0))
