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
			# One upward arrow: a shaft and a head, no taller than the others.
			var shaft := BoxMesh.new()
			shaft.size = Vector3(0.2, 0.36, 0.2)
			_body.add_child(Mats.mesh(shaft, lit, Vector3.UP * -0.2))
			var head := CylinderMesh.new()
			head.top_radius = 0.0
			head.bottom_radius = 0.36
			head.height = 0.42
			head.radial_segments = 4
			_body.add_child(Mats.mesh(head, lit, Vector3.UP * 0.18))
		PowerUps.Kind.BOOST:
			# Three chevrons in a row, like the pads on the floor.
			for index in 3:
				var wedge := PrismMesh.new()
				wedge.size = Vector3(0.62, 0.42, 0.3)
				var chevron := Mats.mesh(wedge, lit, Vector3(0.0, 0.0, 0.42 - index * 0.42))
				chevron.rotation.x = -PI / 2.0
				_body.add_child(chevron)
		PowerUps.Kind.FEATHER:
			# A feather: a leaf-shaped vane leaning on a quill that pokes out
			# below it.
			var feather := Node3D.new()
			feather.rotation.z = -0.45
			_body.add_child(feather)
			var vane := SphereMesh.new()
			vane.radius = 0.5
			vane.height = 1.0
			# Two vanes at right angles: a single flat one vanishes edge-on
			# every half turn.
			for turn: float in [0.0, PI / 2.0]:
				var blade := Mats.mesh(vane, pale, Vector3.UP * 0.12)
				blade.scale = Vector3(0.36, 0.72, 0.07)
				blade.rotation.y = turn
				feather.add_child(blade)
			var quill := CylinderMesh.new()
			quill.top_radius = 0.012
			quill.bottom_radius = 0.035
			quill.height = 1.05
			feather.add_child(Mats.mesh(quill, lit, Vector3.UP * -0.05))
			# Barbs: short strokes off the quill, so it does not read as a leaf.
			var barb := BoxMesh.new()
			barb.size = Vector3(0.3, 0.025, 0.09)
			for index in 4:
				for side: float in [-1.0, 1.0]:
					for turn: float in [0.0, PI / 2.0]:
						var stroke := Mats.mesh(barb, lit)
						stroke.position = Basis(Vector3.UP, turn) * Vector3(
							side * 0.1, -0.12 + index * 0.17, 0.0)
						stroke.rotation = Vector3(0.0, turn, side * 0.6)
						feather.add_child(stroke)
		PowerUps.Kind.MAGNET:
			# A horseshoe: two legs, a bridge, and pale tips.
			var leg := BoxMesh.new()
			leg.size = Vector3(0.2, 0.62, 0.22)
			var tip := BoxMesh.new()
			tip.size = Vector3(0.22, 0.18, 0.24)
			for side: float in [-1.0, 1.0]:
				_body.add_child(Mats.mesh(leg, lit, Vector3(side * 0.3, 0.0, 0.0)))
				_body.add_child(Mats.mesh(tip, pale, Vector3(side * 0.3, 0.4, 0.0)))
			var bridge := BoxMesh.new()
			bridge.size = Vector3(0.8, 0.2, 0.22)
			_body.add_child(Mats.mesh(bridge, lit, Vector3(0.0, -0.36, 0.0)))
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
