class_name Gate
extends StaticBody3D
## A barred gate. Solid until the marble touches it while carrying a key.

signal touched(gate: Gate)

const HEIGHT := 2.4

var is_open: bool = false

var _collider: CollisionShape3D
var _bars := Node3D.new()


func _init(width: float = 4.0) -> void:
	var shape := BoxShape3D.new()
	shape.size = Vector3(width, HEIGHT, 0.4)
	_collider = Mats.collider(shape, Vector3.UP * HEIGHT / 2.0)
	add_child(_collider)
	add_child(_bars)
	var iron := Mats.solid(Color(0.22, 0.24, 0.3), 0.4, 0.7)
	var bar := CylinderMesh.new()
	bar.top_radius = 0.09
	bar.bottom_radius = 0.09
	bar.height = HEIGHT
	var count := maxi(3, int(width / 0.55))
	for index in count:
		var x := -width / 2.0 + width * (index + 0.5) / count
		_bars.add_child(Mats.mesh(bar, iron, Vector3(x, HEIGHT / 2.0, 0.0)))
	var rail := BoxMesh.new()
	rail.size = Vector3(width, 0.2, 0.3)
	for height: float in [0.1, HEIGHT - 0.1]:
		_bars.add_child(Mats.mesh(rail, iron, Vector3(0.0, height, 0.0)))
	var lock := BoxMesh.new()
	lock.size = Vector3(0.6, 0.6, 0.5)
	_bars.add_child(Mats.mesh(lock, Mats.glow(GateKey.COLOR, 0.9), Vector3.UP * HEIGHT / 2.0))


## Drops the gate into the floor and lets the marble through.
func open() -> void:
	if is_open:
		return
	is_open = true
	_collider.set_deferred(&"disabled", true)
	var tween := create_tween()
	tween.tween_property(_bars, ^"position:y", -HEIGHT - 0.3, 0.45).set_ease(Tween.EASE_IN)
	tween.tween_callback(_bars.hide)


func on_marble_hit(_marble: Marble) -> void:
	if not is_open:
		touched.emit(self)
