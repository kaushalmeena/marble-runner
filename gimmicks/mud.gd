class_name Mud
extends Area3D
## A patch of tar. A marble rolling through it is dragged down to a crawl,
## unless it has the grip power-up.

const COLOR := Color(0.2, 0.13, 0.1)
## How quickly the tar bleeds off speed, per second. Against the marble's
## drive this settles at about a third of its normal pace.
const DRAG := 2.8


func _init(size := Vector2(4.0, 4.0)) -> void:
	collision_layer = 0
	collision_mask = 2
	var shape := BoxShape3D.new()
	shape.size = Vector3(size.x, 1.0, size.y)
	add_child(Mats.collider(shape, Vector3.UP * 0.5))
	var sheet := BoxMesh.new()
	sheet.size = Vector3(size.x, 0.04, size.y)
	add_child(Mats.mesh(sheet, Mats.solid(COLOR, 0.25, 0.2), Vector3.UP * 0.03))


func _physics_process(delta: float) -> void:
	for body in get_overlapping_bodies():
		var marble := body as Marble
		if marble == null or not marble.grounded or marble.sure_footed:
			continue
		var velocity := marble.linear_velocity
		var keep := maxf(0.0, 1.0 - DRAG * delta)
		marble.linear_velocity = Vector3(velocity.x * keep, velocity.y, velocity.z * keep)
