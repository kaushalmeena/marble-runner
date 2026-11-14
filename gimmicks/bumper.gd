class_name Bumper
extends StaticBody3D
## A post that kicks the marble away harder than it arrived.

var strength: float = 11.0

var _mesh: MeshInstance3D


func _init(kick: float = 11.0) -> void:
	strength = kick
	var shape := CylinderShape3D.new()
	shape.radius = 0.6
	shape.height = 1.2
	add_child(Mats.collider(shape, Vector3.UP * 0.6))
	var post := CylinderMesh.new()
	post.top_radius = 0.6
	post.bottom_radius = 0.6
	post.height = 1.0
	_mesh = Mats.mesh(post, Mats.glow(Color(1.0, 0.35, 0.45), 0.9), Vector3.UP * 0.5)
	add_child(_mesh)
	var cap := CylinderMesh.new()
	cap.top_radius = 0.72
	cap.bottom_radius = 0.72
	cap.height = 0.2
	add_child(Mats.mesh(cap, Mats.solid(Color(0.95, 0.95, 1.0), 0.3), Vector3.UP * 1.1))


func on_marble_hit(marble: Marble) -> void:
	var away := marble.global_position - global_position
	away.y = 0.0
	if away.length_squared() < 0.0001:
		away = Vector3.BACK
	marble.boost(away, strength)
	Audio.play(&"bumper", -3.0, 0.08)
	var tween := create_tween()
	tween.tween_property(_mesh, ^"scale", Vector3(1.3, 1.0, 1.3), 0.05)
	tween.tween_property(_mesh, ^"scale", Vector3.ONE, 0.25) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
