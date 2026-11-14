class_name GateKey
extends Area3D
## A key. Carried until it is spent on a gate.

signal collected(key: GateKey)

const COLOR := Color(1.0, 0.8, 0.25)
const HOVER := 0.95

var _body := Node3D.new()
var _time: float = 0.0
var _taken: bool = false


func _init() -> void:
	collision_layer = 0
	collision_mask = 2
	var shape := SphereShape3D.new()
	shape.radius = 0.85
	add_child(Mats.collider(shape, Vector3.UP * HOVER))
	_body.position = Vector3.UP * HOVER
	add_child(_body)
	var gold := Mats.glow(COLOR, 0.9)
	var bow := TorusMesh.new()
	bow.inner_radius = 0.13
	bow.outer_radius = 0.27
	var loop := Mats.mesh(bow, gold, Vector3.UP * 0.28)
	loop.rotation.x = PI / 2.0
	_body.add_child(loop)
	var shaft := BoxMesh.new()
	shaft.size = Vector3(0.1, 0.6, 0.1)
	_body.add_child(Mats.mesh(shaft, gold, Vector3.UP * -0.22))
	var tooth := BoxMesh.new()
	tooth.size = Vector3(0.2, 0.09, 0.1)
	for height: float in [-0.48, -0.3]:
		_body.add_child(Mats.mesh(tooth, gold, Vector3(0.14, height, 0.0)))
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	_body.rotate_y(delta * 2.0)
	_body.position.y = HOVER + sin(_time * 2.2) * 0.1


func _on_body_entered(body: Node3D) -> void:
	if _taken or not body is Marble:
		return
	_taken = true
	hide()
	set_deferred(&"monitoring", false)
	collected.emit(self)
