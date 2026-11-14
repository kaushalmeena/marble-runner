class_name BouncePad
extends Area3D
## A spring that throws the marble straight up.

var speed: float = 14.0

var _cap: MeshInstance3D


func _init(launch_speed: float = 14.0) -> void:
	speed = launch_speed
	collision_layer = 0
	collision_mask = 2
	var shape := CylinderShape3D.new()
	shape.radius = 1.1
	shape.height = 0.9
	add_child(Mats.collider(shape, Vector3.UP * 0.45))

	var base := CylinderMesh.new()
	base.top_radius = 1.25
	base.bottom_radius = 1.25
	base.height = 0.1
	add_child(Mats.mesh(base, Mats.solid(Color(0.1, 0.1, 0.16), 0.4), Vector3.UP * 0.05))
	var cap := CylinderMesh.new()
	cap.top_radius = 0.95
	cap.bottom_radius = 1.1
	cap.height = 0.22
	_cap = Mats.mesh(cap, Mats.glow(Color(1.0, 0.45, 0.75), 1.2), Vector3.UP * 0.2)
	add_child(_cap)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	var marble := body as Marble
	if marble == null:
		return
	marble.launch(speed)
	Audio.play(&"bounce", -3.0, 0.05)
	var tween := create_tween()
	tween.tween_property(_cap, ^"position:y", 0.5, 0.06)
	tween.tween_property(_cap, ^"position:y", 0.2, 0.3) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
