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

var _trauma: float = 0.0
var _time: float = 0.0
var _rest_transform: Transform3D
var _noise := FastNoiseLite.new()


func _ready() -> void:
	_rest_transform = transform
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.frequency = 1.0
	set_process(false)


## Adds to the shake, clamped so repeated hits cannot stack into nausea.
func add_trauma(amount: float) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)
	set_process(_trauma > 0.0)


func _process(delta: float) -> void:
	_time += delta
	_trauma = maxf(0.0, _trauma - decay * delta)
	if _trauma <= 0.0:
		transform = _rest_transform
		set_process(false)
		return
	# Squared so the falloff is felt rather than linear.
	var shake := _trauma * _trauma
	var t := _time * frequency
	transform = _rest_transform
	translate_object_local(Vector3(
		max_offset.x * shake * _noise.get_noise_2d(t, 0.0),
		max_offset.y * shake * _noise.get_noise_2d(0.0, t),
		max_offset.z * shake * _noise.get_noise_2d(t, t)
	))
	rotate_object_local(Vector3.BACK, max_roll * shake * _noise.get_noise_2d(t, 512.0))
