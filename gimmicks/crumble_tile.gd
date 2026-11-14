class_name CrumbleTile
extends StaticBody3D
## A tile that drops away shortly after it is touched, then grows back.

const WARN_SECONDS := 0.9
const GONE_SECONDS := 3.0

var _mesh: MeshInstance3D
var _collider: CollisionShape3D
var _busy: bool = false


func _init(size := Vector3(3.0, 0.5, 3.0)) -> void:
	var shape := BoxShape3D.new()
	shape.size = size
	_collider = Mats.collider(shape)
	add_child(_collider)
	var box := BoxMesh.new()
	box.size = size - Vector3(0.12, 0.0, 0.12)
	_mesh = Mats.mesh(box, Mats.solid(Color(0.86, 0.62, 0.36), 0.85))
	add_child(_mesh)


func on_marble_hit(_marble: Marble) -> void:
	if _busy:
		return
	_busy = true
	Audio.play(&"crumble", -6.0, 0.1)
	var shake := create_tween().set_loops(5)
	shake.tween_property(_mesh, ^"position:x", 0.06, WARN_SECONDS / 10.0)
	shake.tween_property(_mesh, ^"position:x", -0.06, WARN_SECONDS / 10.0)
	await shake.finished
	_collider.set_deferred(&"disabled", true)
	var fall := create_tween().set_parallel()
	fall.tween_property(_mesh, ^"position:y", -6.0, 0.5).set_ease(Tween.EASE_IN)
	fall.tween_property(_mesh, ^"scale", Vector3.ONE * 0.2, 0.5)
	await get_tree().create_timer(GONE_SECONDS, false).timeout
	_mesh.position = Vector3.ZERO
	_mesh.scale = Vector3.ONE * 0.01
	_collider.set_deferred(&"disabled", false)
	var grow := create_tween()
	grow.tween_property(_mesh, ^"scale", Vector3.ONE, 0.3) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await grow.finished
	_busy = false
