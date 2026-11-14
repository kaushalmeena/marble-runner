class_name Conveyor
extends Area3D
## A belt that carries the marble along its arrows.
##
## The floor under it does not move. The belt pushes a marble standing on it
## up to belt speed and no further, so rolling with it is fast, standing still
## is a ride, and rolling against it is slow going rather than impossible.

const CHEVRON_GAP := 1.5

## Speed a marble at rest is carried at, along the belt's forward (-Z) axis.
var speed: float = 5.0
## How hard the belt pulls, as an acceleration.
var pull: float = 9.0

var _length: float
var _chevrons: Array[MeshInstance3D] = []
var _scroll: float = 0.0


func _init(size := Vector2(3.0, 8.0), belt_speed: float = 5.0) -> void:
	speed = belt_speed
	_length = size.y
	collision_layer = 0
	collision_mask = 2
	var shape := BoxShape3D.new()
	shape.size = Vector3(size.x, 1.0, size.y)
	add_child(Mats.collider(shape, Vector3.UP * 0.5))

	var plate := BoxMesh.new()
	plate.size = Vector3(size.x, 0.05, size.y)
	add_child(Mats.mesh(plate, Mats.solid(Color(0.1, 0.11, 0.14), 0.5, 0.3), Vector3.UP * 0.03))
	var arrow := PrismMesh.new()
	arrow.size = Vector3(size.x * 0.55, 0.5, 0.04)
	var lit := Mats.glow(Color(1.0, 0.72, 0.2), 1.0)
	for index in int(size.y / CHEVRON_GAP):
		var chevron := Mats.mesh(arrow, lit)
		# A prism stands upright; laid flat it is an arrowhead pointing -Z.
		chevron.rotation.x = -PI / 2.0
		add_child(chevron)
		_chevrons.append(chevron)
	_place_chevrons()


func _process(delta: float) -> void:
	_scroll = fposmod(_scroll + speed * delta, CHEVRON_GAP)
	_place_chevrons()


func _physics_process(_delta: float) -> void:
	var along := -global_basis.z
	for body in get_overlapping_bodies():
		var marble := body as Marble
		if marble == null or not marble.grounded:
			continue
		var short := speed - marble.linear_velocity.dot(along)
		if short > 0.0:
			marble.apply_central_force(along * marble.mass * pull * minf(1.0, short / 2.0))


## Slides the arrows down the belt and wraps them, so the belt reads as moving.
func _place_chevrons() -> void:
	for index in _chevrons.size():
		var z := _length / 2.0 - 0.4 - fposmod(index * CHEVRON_GAP + _scroll, _length - 0.8)
		_chevrons[index].position = Vector3(0.0, 0.07, z)
