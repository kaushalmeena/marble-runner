class_name Bridge
extends StaticBody3D
## A slab of hard light that is only there while its floor button is down.
##
## Off, it is a faint outline of where it will be, and the marble falls
## straight through it.

const COLOR := Color(0.3, 0.9, 1.0)

var _shape: CollisionShape3D
var _slab: MeshInstance3D
var _solid: Material = Mats.glow(COLOR, 0.55)
var _faint: Material = Mats.ghost(COLOR, 0.1)


func _init(size := Vector3(4.0, 0.4, 6.0)) -> void:
	var box := BoxShape3D.new()
	box.size = size
	_shape = Mats.collider(box)
	add_child(_shape)
	var mesh := BoxMesh.new()
	mesh.size = size
	_slab = Mats.mesh(mesh, _faint)
	_slab.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_slab)
	switch_to(false)


func switch_to(on: bool) -> void:
	_shape.set_deferred(&"disabled", not on)
	_slab.material_override = _solid if on else _faint
