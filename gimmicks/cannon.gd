class_name Cannon
extends Area3D
## A cannon that fires the marble in an arc to a set landing spot.
##
## The shot is worked out when it is fired, from wherever gravity stands at
## that moment, so the landing spot is the same on the moon, on a heavy world
## or weighed down by a trap.

## The marble has just been fired.
signal fired

const COLOR := Color(1.0, 0.55, 0.15)
const MUZZLE := Vector3(0.0, 1.0, 0.0)

## Where the marble comes down, relative to the cannon's base.
var reach := Vector3(0.0, 0.0, -20.0)
## Seconds the marble is in the air.
var flight: float = 1.6

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _init(offset := Vector3(0.0, 0.0, -20.0), air_seconds: float = 1.6) -> void:
	reach = offset
	flight = air_seconds
	collision_layer = 0
	collision_mask = 2
	var shape := CylinderShape3D.new()
	shape.radius = 1.0
	shape.height = 1.4
	add_child(Mats.collider(shape, Vector3.UP * 0.7))
	var base := CylinderMesh.new()
	base.top_radius = 1.3
	base.bottom_radius = 1.45
	base.height = 0.12
	add_child(Mats.mesh(base, Mats.solid(Color(0.12, 0.13, 0.17), 0.4, 0.6), Vector3.UP * 0.06))
	var ring := TorusMesh.new()
	ring.inner_radius = 1.0
	ring.outer_radius = 1.2
	var rim := Mats.mesh(ring, Mats.glow(COLOR, 1.4), Vector3.UP * 0.14)
	rim.scale.y = 0.3
	add_child(rim)
	# An open barrel leaning the way the shot will go.
	var tube := CylinderMesh.new()
	tube.top_radius = 0.9
	tube.bottom_radius = 0.78
	tube.height = 1.3
	tube.cap_top = false
	tube.cap_bottom = false
	var metal := Mats.solid(Color(0.16, 0.18, 0.24), 0.35, 0.7)
	metal.cull_mode = BaseMaterial3D.CULL_DISABLED
	var barrel := Mats.mesh(tube, metal)
	var aim := _shot(1.0).normalized()
	barrel.basis = Basis(Quaternion(Vector3.UP, aim))
	barrel.position = Vector3.UP * 0.12 + aim * 0.7
	add_child(barrel)
	body_entered.connect(_on_body_entered)


## The velocity that lands on the target under [param gravity_scale], for a
## body that loses [param drag] of its speed per second to the air. The drag
## matters: over a two second flight the marble's own damping would otherwise
## drop it a quarter of the way short.
func _shot(gravity_scale: float, drag: float = 0.0) -> Vector3:
	var span := reach - MUZZLE + Vector3.UP * Marble.RADIUS
	var gravity := _gravity * gravity_scale
	if drag < 0.001:
		return span / flight + Vector3.UP * 0.5 * gravity * flight
	# With drag k, distance covered in time T is v0 * (1 - e^-kT) / k, and
	# gravity settles toward a terminal fall of g / k.
	var carry := (1.0 - exp(-drag * flight)) / drag
	var velocity := span / carry
	velocity.y = (span.y + gravity * flight / drag) / carry - gravity / drag
	return velocity


func _on_body_entered(body: Node3D) -> void:
	var marble := body as Marble
	if marble == null:
		return
	var drag: float = marble.linear_damp + float(
		ProjectSettings.get_setting("physics/3d/default_linear_damp"))
	marble.teleport(global_position + MUZZLE, _shot(marble.gravity_scale, drag))
	Audio.play(&"boost", -2.0, 0.0, 0.7)
	fired.emit()
