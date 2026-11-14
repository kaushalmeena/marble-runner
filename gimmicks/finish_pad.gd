class_name FinishPad
extends Area3D
## The goal. Stays locked, and red, until every gem has been collected.

signal reached(pad: FinishPad)

const LOCKED_COLOR := Color(1.0, 0.3, 0.25)
const OPEN_COLOR := Color(0.35, 1.0, 0.55)

var locked: bool = true:
	set(value):
		locked = value
		_refresh()

var _ring_material: StandardMaterial3D
var _beam_material: StandardMaterial3D
var _beam: MeshInstance3D
var _time: float = 0.0


func _init() -> void:
	collision_layer = 0
	collision_mask = 2
	var shape := CylinderShape3D.new()
	shape.radius = 1.4
	shape.height = 2.0
	add_child(Mats.collider(shape, Vector3.UP))

	var base := CylinderMesh.new()
	base.top_radius = 1.7
	base.bottom_radius = 1.7
	base.height = 0.1
	_ring_material = Mats.glow(LOCKED_COLOR, 1.4)
	add_child(Mats.mesh(base, _ring_material, Vector3.UP * 0.05))

	var column := CylinderMesh.new()
	column.top_radius = 1.5
	column.bottom_radius = 1.5
	column.height = 14.0
	column.cap_top = false
	column.cap_bottom = false
	_beam_material = Mats.ghost(LOCKED_COLOR, 0.16)
	_beam = Mats.mesh(column, _beam_material, Vector3.UP * 7.0)
	_beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_beam)
	body_entered.connect(_on_body_entered)
	_refresh()


func _process(delta: float) -> void:
	_time += delta
	var pulse := 0.16 + 0.07 * sin(_time * 3.0)
	_beam_material.albedo_color.a = pulse if not locked else 0.08


func _refresh() -> void:
	if _ring_material == null:
		return
	var color := LOCKED_COLOR if locked else OPEN_COLOR
	_ring_material.albedo_color = color
	_ring_material.emission = color
	_beam_material.albedo_color = Color(color, 0.16)


func _on_body_entered(body: Node3D) -> void:
	if body is Marble:
		reached.emit(self)
