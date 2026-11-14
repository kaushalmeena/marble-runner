class_name Checkpoint
extends Area3D
## Where the marble comes back after falling. The last one touched wins.

signal reached(checkpoint: Checkpoint)

const IDLE_COLOR := Color(0.6, 0.7, 0.85)
const ACTIVE_COLOR := Color(0.3, 0.85, 1.0)

var active: bool = false:
	set(value):
		active = value
		var color := ACTIVE_COLOR if active else IDLE_COLOR
		_material.albedo_color = color
		_material.emission = color
		_material.emission_energy_multiplier = 1.8 if active else 0.3

var _material: StandardMaterial3D


func _init() -> void:
	collision_layer = 0
	collision_mask = 2
	var shape := CylinderShape3D.new()
	shape.radius = 1.4
	shape.height = 2.4
	add_child(Mats.collider(shape, Vector3.UP * 1.2))
	var ring := TorusMesh.new()
	ring.inner_radius = 1.05
	ring.outer_radius = 1.3
	ring.rings = 32
	ring.ring_segments = 8
	_material = Mats.glow(IDLE_COLOR, 0.3)
	var mesh := Mats.mesh(ring, _material, Vector3.UP * 0.04)
	mesh.scale.y = 0.35
	add_child(mesh)
	body_entered.connect(_on_body_entered)


## Where a respawning marble should be put.
func spawn_position() -> Vector3:
	return global_position + Vector3.UP * (Marble.RADIUS + 0.4)


func _on_body_entered(body: Node3D) -> void:
	if body is Marble and not active:
		reached.emit(self)
