class_name FloorButton
extends Area3D
## A button in the floor. Rolling over it switches on everything wired to it:
## bridges appear, beams go out.
##
## With [member seconds] above zero it springs back up after that long and
## everything switches off again, so the crossing it opened is a race.

const COLOR := Color(1.0, 0.35, 0.8)

## Things with a [code]switch_to(on)[/code] method.
var targets: Array = []
## How long it stays down. Zero is for good.
var seconds: float = 0.0
var down: bool = false

var _cap: MeshInstance3D
var _ring: MeshInstance3D


func _init(hold_seconds: float = 0.0) -> void:
	seconds = hold_seconds
	collision_layer = 0
	collision_mask = 2
	var shape := CylinderShape3D.new()
	shape.radius = 0.9
	shape.height = 1.0
	add_child(Mats.collider(shape, Vector3.UP * 0.5))
	var base := CylinderMesh.new()
	base.top_radius = 1.05
	base.bottom_radius = 1.15
	base.height = 0.08
	add_child(Mats.mesh(base, Mats.solid(Color(0.12, 0.13, 0.17), 0.4, 0.5), Vector3.UP * 0.04))
	var cap := CylinderMesh.new()
	cap.top_radius = 0.75
	cap.bottom_radius = 0.75
	cap.height = 0.16
	_cap = Mats.mesh(cap, Mats.glow(COLOR, 1.2), Vector3.UP * 0.14)
	add_child(_cap)
	# A timed button wears a ring that drains as its time runs out.
	var ring := TorusMesh.new()
	ring.inner_radius = 1.25
	ring.outer_radius = 1.4
	_ring = Mats.mesh(ring, Mats.glow(COLOR, 1.0), Vector3.UP * 0.05)
	_ring.scale = Vector3(1.0, 0.25, 1.0)
	_ring.visible = false
	add_child(_ring)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if down or not body is Marble:
		return
	_set_down(true)
	Audio.play(&"unlock", -4.0, 0.0, 1.25)
	if seconds <= 0.0:
		return
	_ring.visible = true
	_ring.scale = Vector3(1.0, 0.25, 1.0)
	var drain := create_tween()
	drain.tween_property(_ring, ^"scale", Vector3(0.55, 0.25, 0.55), seconds)
	drain.tween_callback(_release)


func _release() -> void:
	_ring.visible = false
	_set_down(false)
	Audio.play(&"power_down", -8.0)


func _set_down(pressed: bool) -> void:
	down = pressed
	_cap.position.y = 0.07 if pressed else 0.14
	for target: Object in targets:
		target.switch_to(pressed)
