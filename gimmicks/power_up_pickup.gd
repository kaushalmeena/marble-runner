class_name PowerUpPickup
extends Area3D
## A power-up waiting to be collected. Comes back a few seconds after it is
## taken, so a wasted one never leaves a level unfinishable.

signal taken(pickup: PowerUpPickup)

const RESPAWN_SECONDS := 6.0
const HOVER := 0.95
const FONT := preload("res://assets/fonts/Outfit.ttf")

var kind: PowerUps.Kind = PowerUps.Kind.SUPER_JUMP

var _body: Node3D
var _time: float = 0.0
var _available: bool = true


func _init(power_up: PowerUps.Kind = PowerUps.Kind.SUPER_JUMP) -> void:
	kind = power_up
	collision_layer = 0
	collision_mask = 2
	var shape := SphereShape3D.new()
	shape.radius = 0.9
	add_child(Mats.collider(shape, Vector3.UP * HOVER))

	var color := PowerUps.color(kind)
	_body = Node3D.new()
	_body.position = Vector3.UP * HOVER
	add_child(_body)
	_body.add_child(Mats.mesh(_core_mesh(), Mats.glow(color, 1.3)))
	var shell := SphereMesh.new()
	shell.radius = 0.62
	shell.height = 1.24
	var bubble := Mats.mesh(shell, Mats.ghost(color, 0.22))
	bubble.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_body.add_child(bubble)

	# Names the pickup in the world, so nobody has to learn a colour code.
	var label := Label3D.new()
	label.text = PowerUps.label(kind)
	label.font = FONT
	label.font_size = 40
	label.outline_size = 10
	label.pixel_size = 0.006
	label.modulate = color.lightened(0.4)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3.UP * (HOVER + 0.95)
	add_child(label)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	_body.rotate_y(delta * 1.6)
	_body.position.y = HOVER + sin(_time * 2.0) * 0.08


## Each kind gets its own silhouette inside the bubble.
func _core_mesh() -> Mesh:
	match kind:
		PowerUps.Kind.SUPER_JUMP:
			var cone := CylinderMesh.new()
			cone.top_radius = 0.0
			cone.bottom_radius = 0.32
			cone.height = 0.6
			return cone
		PowerUps.Kind.BOOST:
			var wedge := PrismMesh.new()
			wedge.size = Vector3(0.6, 0.5, 0.25)
			return wedge
		PowerUps.Kind.FEATHER:
			var disc := CylinderMesh.new()
			disc.top_radius = 0.38
			disc.bottom_radius = 0.38
			disc.height = 0.08
			return disc
		PowerUps.Kind.MAGNET:
			var ring := TorusMesh.new()
			ring.inner_radius = 0.18
			ring.outer_radius = 0.38
			return ring
	var cube := BoxMesh.new()
	cube.size = Vector3.ONE * 0.45
	return cube


func _on_body_entered(body: Node3D) -> void:
	if not _available or not body is Marble:
		return
	_available = false
	hide()
	taken.emit(self)
	await get_tree().create_timer(RESPAWN_SECONDS, false).timeout
	_available = true
	show()
