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
			# A feather: one flat leaf-shaped vane on a quill that pokes out
			# below it, with barbs drawn across the vane.
			var feather := Node3D.new()
			feather.rotation.z = -0.45
			_body.add_child(feather)
			var half := Vector2(0.19, 0.38)
			var middle := 0.12
			var vane := SphereMesh.new()
			vane.radius = 0.5
			vane.height = 1.0
			var blade := Mats.mesh(vane, pale, Vector3.UP * middle)
			blade.scale = Vector3(half.x * 2.0, half.y * 2.0, 0.06)
			feather.add_child(blade)
			var quill := CylinderMesh.new()
			quill.top_radius = 0.012
			quill.bottom_radius = 0.035
			quill.height = 0.98
			feather.add_child(Mats.mesh(quill, lit, Vector3.UP * -0.02))
			# The quill is thinner than the vane is thick, so inside the vane it
			# is buried. A spine as deep as the barbs shows it on both faces.
			var spine := BoxMesh.new()
			spine.size = Vector3(0.03, half.y * 1.84, 0.075)
			feather.add_child(Mats.mesh(spine, lit, Vector3.UP * middle))
			# Each barb runs from the quill up and out, and stops short of the
			# vane's edge at the height its tip reaches, so none pokes outside.
			const SLANT := 0.5
			for index in 5:
				var root := -0.24 + index * 0.115
				for side: float in [-1.0, 1.0]:
					var reach := 0.0
					for _pass in 4:
						var tip := root + tan(SLANT) * reach
						reach = half.x * sqrt(maxf(0.0, 1.0 - pow(tip / half.y, 2.0))) * 0.8
					if reach < 0.03:
						continue
					var barb := BoxMesh.new()
					barb.size = Vector3(reach / cos(SLANT), 0.022, 0.075)
					var stroke := Mats.mesh(barb, lit, Vector3(
						side * reach / 2.0, middle + root + tan(SLANT) * reach / 2.0, 0.0))
					stroke.rotation.z = side * SLANT
					feather.add_child(stroke)
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
