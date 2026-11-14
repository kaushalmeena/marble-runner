class_name Gem
extends Area3D
## A collectible. Every gem in a level must be collected to open the finish.

signal collected(gem: Gem)

const COLORS: Array[Color] = [
	Color(0.3, 0.85, 1.0),
	Color(1.0, 0.45, 0.6),
	Color(0.55, 1.0, 0.5),
	Color(1.0, 0.8, 0.3),
	Color(0.75, 0.55, 1.0),
]
## Height of the gem's centre above the point it was placed at.
const HOVER := 0.9

var color := COLORS[0]
## Where the gem was placed, so the magnet can only ever pull it, not lose it.
var taken: bool = false

var _mesh: MeshInstance3D
var _time: float = 0.0


func _init(color_index: int = 0) -> void:
	color = COLORS[color_index % COLORS.size()]
	collision_layer = 0
	collision_mask = 2
	var shape := SphereShape3D.new()
	shape.radius = 0.8
	add_child(Mats.collider(shape, Vector3.UP * HOVER))
	# Six sides and two rings turns a sphere into a cut stone.
	var stone := SphereMesh.new()
	stone.radius = 0.34
	stone.height = 0.9
	stone.radial_segments = 6
	stone.rings = 2
	_mesh = Mats.mesh(stone, Mats.glow(color, 1.1), Vector3.UP * HOVER)
	add_child(_mesh)
	_time = randf() * TAU
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	_mesh.rotate_y(delta * 2.2)
	_mesh.position.y = HOVER + sin(_time * 2.4) * 0.1


func _on_body_entered(body: Node3D) -> void:
	if taken or not body is Marble:
		return
	taken = true
	hide()
	set_deferred(&"monitoring", false)
	collected.emit(self)
