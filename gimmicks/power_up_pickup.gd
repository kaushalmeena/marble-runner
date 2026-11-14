class_name PowerUpPickup
extends Area3D
## A power-up waiting to be collected. Comes back a few seconds after it is
## taken, so a wasted one never leaves a level unfinishable.

signal taken(pickup: PowerUpPickup)

const RESPAWN_SECONDS := 6.0
const HOVER := 0.95
const FONT := preload("res://assets/fonts/Outfit.ttf")
## OpenType tag for the weight axis ("wght"). String keys are silently ignored.
const WEIGHT_AXIS := 2003265652

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
	_build_icon(color)
	_body.scale = Vector3.ONE * 1.3
	# A ring on the floor marks the spot from above and from a distance.
	var ring := TorusMesh.new()
	ring.inner_radius = 0.62
	ring.outer_radius = 0.78
	var base := Mats.mesh(ring, Mats.glow(color, 1.0), Vector3.UP * 0.04)
	base.scale.y = 0.3
	add_child(base)

	# Names the pickup in the world, so nobody has to learn a colour code.
	var label := Label3D.new()
	label.text = PowerUps.label(kind)
	# The font file's default weight is hairline thin; ask for bold.
	var bold := FontVariation.new()
	bold.base_font = FONT
	bold.variation_opentype = {WEIGHT_AXIS: 800}
	label.font = bold
	label.font_size = 48
	label.outline_size = 14
	label.pixel_size = 0.0075
	label.modulate = color.lightened(0.5)
	label.outline_modulate = Color(0.03, 0.05, 0.1, 0.9)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3.UP * (HOVER + 1.05)
	add_child(label)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	_body.rotate_y(delta * 1.6)
	_body.position.y = HOVER + sin(_time * 2.0) * 0.08


## Each kind is a different object, not a different colour of the same one:
## the silhouette has to be readable at a glance, mid-roll.
func _build_icon(color: Color) -> void:
	var lit := Mats.glow(color, 0.9)
	var pale := Mats.glow(Color(1.0, 1.0, 1.0), 0.5)
	match kind:
		PowerUps.Kind.SUPER_JUMP:
			# Two triangles stacked and pointing up: the boost chevrons, stood
			# on end.
			for height: float in [-0.2, 0.2]:
				var triangle := PrismMesh.new()
				triangle.size = Vector3(0.62, 0.4, 0.2)
				_body.add_child(Mats.mesh(triangle, lit, Vector3.UP * height))
		PowerUps.Kind.BOOST:
			# Two triangles side by side and pointing along: super jump turned
			# on its side, a fast-forward sign.
			for along: float in [-0.2, 0.2]:
				var triangle := PrismMesh.new()
				triangle.size = Vector3(0.62, 0.4, 0.2)
				var arrow := Mats.mesh(triangle, lit, Vector3.RIGHT * along)
				arrow.rotation.z = -PI / 2.0
				_body.add_child(arrow)
		PowerUps.Kind.FEATHER:
			# A feather in two shapes: a thick oval vane, and one bold quill
			# running through it and out of the bottom.
			var feather := Node3D.new()
			feather.rotation.z = -0.45
			_body.add_child(feather)
			var oval := CylinderMesh.new()
			oval.top_radius = 0.4
			oval.bottom_radius = 0.4
			oval.height = 0.14
			var vane := Mats.mesh(oval, pale, Vector3.UP * 0.12)
			vane.rotation.x = PI / 2.0
			vane.scale = Vector3(0.52, 1.0, 1.0)
			feather.add_child(vane)
			var quill := BoxMesh.new()
			quill.size = Vector3(0.07, 1.0, 0.2)
			feather.add_child(Mats.mesh(quill, lit, Vector3.UP * -0.06))
		PowerUps.Kind.MAGNET:
			# A horseshoe: a round bend at the bottom, two legs, and pale tips.
			const BEND_RADIUS := 0.3
			const THICKNESS := 0.2
			const DEPTH := 0.22
			const SEGMENTS := 12
			# The bend is a half circle of short blocks, overlapped so no gaps
			# show on the outside of the curve.
			var block := BoxMesh.new()
			block.size = Vector3(PI * BEND_RADIUS / SEGMENTS * 1.5, THICKNESS, DEPTH)
			for index in SEGMENTS + 1:
				var angle := PI + PI * index / SEGMENTS
				var piece := Mats.mesh(block, lit, Vector3(
					cos(angle) * BEND_RADIUS, sin(angle) * BEND_RADIUS, 0.0))
				piece.rotation.z = angle + PI / 2.0
				_body.add_child(piece)
			var leg := BoxMesh.new()
			leg.size = Vector3(THICKNESS, 0.3, DEPTH)
			var tip := BoxMesh.new()
			tip.size = Vector3(THICKNESS + 0.02, 0.16, DEPTH + 0.02)
			for side: float in [-1.0, 1.0]:
				_body.add_child(Mats.mesh(leg, lit, Vector3(side * BEND_RADIUS, 0.15, 0.0)))
				_body.add_child(Mats.mesh(tip, pale, Vector3(side * BEND_RADIUS, 0.38, 0.0)))
		PowerUps.Kind.SHIELD:
			# A round shield, face on, with a pale boss in the middle.
			var plate := CylinderMesh.new()
			plate.top_radius = 0.46
			plate.bottom_radius = 0.46
			plate.height = 0.12
			var face := Mats.mesh(plate, lit)
			face.rotation.x = PI / 2.0
			_body.add_child(face)
			var boss := SphereMesh.new()
			boss.radius = 0.2
			boss.height = 0.4
			var stud := Mats.mesh(boss, pale)
			stud.scale.z = 0.6
			_body.add_child(stud)
		PowerUps.Kind.DOUBLE_JUMP:
			# A coiled spring: three rings stacked.
			for height: float in [-0.26, 0.0, 0.26]:
				var coil := TorusMesh.new()
				coil.inner_radius = 0.22
				coil.outer_radius = 0.38
				var ring_mesh := Mats.mesh(coil, lit if height != 0.0 else pale, Vector3.UP * height)
				ring_mesh.scale.y = 0.7
				_body.add_child(ring_mesh)
		PowerUps.Kind.STOPWATCH:
			# A clock face on edge, with hands and a crown.
			var face := CylinderMesh.new()
			face.top_radius = 0.48
			face.bottom_radius = 0.48
			face.height = 0.14
			var dial := Mats.mesh(face, lit)
			dial.rotation.x = PI / 2.0
			_body.add_child(dial)
			var hand := BoxMesh.new()
			hand.size = Vector3(0.07, 0.36, 0.2)
			_body.add_child(Mats.mesh(hand, pale, Vector3(0.0, 0.15, 0.0)))
			var short_hand := BoxMesh.new()
			short_hand.size = Vector3(0.24, 0.07, 0.2)
			_body.add_child(Mats.mesh(short_hand, pale, Vector3(0.1, 0.0, 0.0)))
			var crown := BoxMesh.new()
			crown.size = Vector3(0.16, 0.16, 0.14)
			_body.add_child(Mats.mesh(crown, pale, Vector3(0.0, 0.58, 0.0)))


func _on_body_entered(body: Node3D) -> void:
	if not _available or not body is Marble:
		return
	_available = false
	hide()
	taken.emit(self)
	await get_tree().create_timer(RESPAWN_SECONDS, false).timeout
	_available = true
	show()
