class_name SecretDiamond
extends Area3D
## The one secret in a level: a diamond, off the route or behind a trick.
##
## It never blocks the finish. Some start out of sight and only appear when
## something wired to them is set off: a hidden floor button, a rival popped.

signal collected(diamond: SecretDiamond)

const COLOR := Color(0.86, 0.95, 1.0)
const HOVER := 0.9

var taken: bool = false
## True while the diamond is waiting on a button or a rival to bring it out.
var concealed: bool = false

var _body := Node3D.new()
var _time: float = 0.0


func _init(start_concealed: bool = false) -> void:
	concealed = start_concealed
	collision_layer = 0
	collision_mask = 2
	var shape := SphereShape3D.new()
	shape.radius = 0.8
	add_child(Mats.collider(shape, Vector3.UP * HOVER))
	_body.position = Vector3.UP * HOVER
	add_child(_body)
	# A brilliant cut: a low crown over a deep point, eight-sided, so every
	# facet catches the light as it turns.
	# Lit gently: a strong glow would wash the facets out to a white blob.
	var bright := Mats.glow(COLOR, 0.35)
	var crown := CylinderMesh.new()
	crown.top_radius = 0.26
	crown.bottom_radius = 0.46
	crown.height = 0.2
	crown.radial_segments = 8
	crown.rings = 1
	_body.add_child(Mats.mesh(crown, bright, Vector3.UP * 0.2))
	var point := CylinderMesh.new()
	point.top_radius = 0.46
	point.bottom_radius = 0.0
	point.height = 0.5
	point.radial_segments = 8
	point.rings = 1
	_body.add_child(Mats.mesh(point, Mats.glow(COLOR.darkened(0.18), 0.3), Vector3.UP * -0.15))
	body_entered.connect(_on_body_entered)
	if concealed:
		hide()
		monitoring = false


func _process(delta: float) -> void:
	_time += delta
	_body.rotate_y(delta * 2.6)
	_body.position.y = HOVER + sin(_time * 2.0) * 0.1


## Fades the diamond, for a level whose secret the player already holds. It can
## still be picked up; it just no longer looks like something to chase.
func dim() -> void:
	for child in _body.get_children():
		(child as MeshInstance3D).material_override = Mats.ghost(COLOR, 0.25)


## Brings a concealed diamond out. Buttons and rivals call this.
func switch_to(on: bool) -> void:
	if not on or not concealed or taken:
		return
	concealed = false
	show()
	set_deferred(&"monitoring", true)
	Audio.play(&"unlock", -4.0, 0.0, 1.5)
	_body.scale = Vector3.ONE * 0.1
	create_tween().tween_property(_body, ^"scale", Vector3.ONE, 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_body_entered(body: Node3D) -> void:
	if taken or not body is Marble:
		return
	taken = true
	hide()
	set_deferred(&"monitoring", false)
	collected.emit(self)
