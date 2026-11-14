class_name Laser
extends TriggerZone
## A red beam between two posts that switches on and off on a timer.
##
## It is a hazard like any red block: touching it while it is lit sends the
## marble back. It flickers for a moment before it lights, so a crossing can
## be timed by eye. A floor button can put it out for good.

const COLOR := Color(1.0, 0.15, 0.2)
const HEIGHT := 0.55
## Flicker before the beam lights.
const WARN_SECONDS := 0.5

var on_seconds: float = 1.5
var off_seconds: float = 1.5
## Seconds into the cycle it starts at. Offsetting neighbours makes a wave.
var phase: float = 0.0

var _beam: MeshInstance3D
var _time: float = 0.0
var _lit: bool = false
var _out: bool = false


func _init(length: float = 6.0, on_for: float = 1.5, off_for: float = 1.5,
		start: float = 0.0) -> void:
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.3, 0.9, length)
	super(shape)
	(get_child(0) as Node3D).position = Vector3.UP * HEIGHT
	one_shot = false
	on_seconds = on_for
	off_seconds = off_for
	phase = start
	# The base class reports every arrival; a beam only counts while lit.
	body_entered.disconnect(_on_body_entered)

	var rod := CylinderMesh.new()
	rod.top_radius = 0.09
	rod.bottom_radius = 0.09
	rod.height = length
	_beam = Mats.mesh(rod, Mats.glow(COLOR, 2.4), Vector3.UP * HEIGHT)
	_beam.rotation.x = PI / 2.0
	_beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_beam)
	var post := BoxMesh.new()
	post.size = Vector3(0.34, 1.0, 0.34)
	var dark := Mats.solid(Color(0.12, 0.13, 0.17), 0.4, 0.6)
	for end: float in [-1.0, 1.0]:
		add_child(Mats.mesh(post, dark, Vector3(0.0, 0.5, end * (length / 2.0 + 0.17))))


func _physics_process(delta: float) -> void:
	if _out:
		return
	_time += delta
	var cycle := fposmod(_time + phase, on_seconds + off_seconds)
	_lit = cycle < on_seconds
	var warning := not _lit and cycle > on_seconds + off_seconds - WARN_SECONDS
	_beam.visible = _lit or (warning and fmod(cycle * 14.0, 2.0) < 1.0)
	_beam.scale = Vector3.ONE if _lit else Vector3(0.35, 1.0, 0.35)
	if not _lit:
		return
	for body in get_overlapping_bodies():
		if body is Marble:
			entered.emit(self)


## A floor button wired to this beam puts it out while the button is down.
func switch_to(on: bool) -> void:
	_out = on
	if on:
		_lit = false
		_beam.visible = false
