class_name Spinner
extends AnimatableBody3D
## A bar that sweeps round a hub at marble height. Jump it or time it.

## Radians per second. Negative turns the other way.
var speed: float = 1.4


func _init(length: float = 8.0, turn_speed: float = 1.4) -> void:
	speed = turn_speed
	var bar_shape := BoxShape3D.new()
	bar_shape.size = Vector3(length, 0.6, 0.5)
	add_child(Mats.collider(bar_shape, Vector3.UP * 0.5))
	var bar := BoxMesh.new()
	bar.size = bar_shape.size
	add_child(Mats.mesh(bar, Mats.glow(Color(1.0, 0.6, 0.2), 0.7), Vector3.UP * 0.5))

	var hub_shape := CylinderShape3D.new()
	hub_shape.radius = 0.55
	hub_shape.height = 1.2
	add_child(Mats.collider(hub_shape, Vector3.UP * 0.6))
	var hub := CylinderMesh.new()
	hub.top_radius = 0.55
	hub.bottom_radius = 0.55
	hub.height = 1.2
	add_child(Mats.mesh(hub, Mats.solid(Color(0.2, 0.22, 0.3), 0.4, 0.6), Vector3.UP * 0.6))


func _physics_process(delta: float) -> void:
	rotate_y(speed * delta)
