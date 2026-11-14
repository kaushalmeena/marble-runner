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
	if PowerUps.is_ailment(kind):
		# Traps sit in a dark bubble, so they never pass for something to want.
		var shell := SphereMesh.new()
		shell.radius = 0.6
		shell.height = 1.2
		var bubble := Mats.mesh(shell, Mats.ghost(Color(0.05, 0.0, 0.08), 0.5))
		bubble.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_body.add_child(bubble)
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
			# A coil spring: wire wound in a helix between two end plates.
			const TURNS := 3.0
			const COIL_RADIUS := 0.27
			const COIL_HEIGHT := 0.62
			const STEPS := 96
			# One continuous tube, not a chain of straight pieces: a chain
			# shows a ridge at every joint.
			var path := PackedVector3Array()
			for step in STEPS + 1:
				path.append(_helix_point(float(step) / STEPS, TURNS, COIL_RADIUS, COIL_HEIGHT))
			_body.add_child(Mats.mesh(Mats.tube(path, 0.05, 12), lit))
			var plate := CylinderMesh.new()
			plate.top_radius = COIL_RADIUS + 0.09
			plate.bottom_radius = COIL_RADIUS + 0.09
			plate.height = 0.07
			for end: float in [-1.0, 1.0]:
				_body.add_child(Mats.mesh(plate, pale, Vector3.UP * end * (COIL_HEIGHT / 2.0 + 0.05)))
		PowerUps.Kind.BOOST:
			# Two triangles side by side and pointing along: super jump turned
			# on its side, a fast-forward sign.
			for along: float in [-0.2, 0.2]:
				var triangle := PrismMesh.new()
				triangle.size = Vector3(0.62, 0.4, 0.2)
				var arrow := Mats.mesh(triangle, lit, Vector3.RIGHT * along)
				arrow.rotation.z = -PI / 2.0
				_body.add_child(arrow)
		PowerUps.Kind.GLIDER:
			_body.add_child(build_glider(lit, pale))
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
			# Two triangles stacked and pointing up: boost stood on end, one
			# arrow for each jump.
			for height: float in [-0.2, 0.2]:
				var triangle := PrismMesh.new()
				triangle.size = Vector3(0.62, 0.4, 0.2)
				_body.add_child(Mats.mesh(triangle, lit, Vector3.UP * height))
		PowerUps.Kind.GRIP:
			# A studded tyre, face on.
			var tyre := TorusMesh.new()
			tyre.inner_radius = 0.24
			tyre.outer_radius = 0.44
			var wheel := Mats.mesh(tyre, lit)
			wheel.rotation.x = PI / 2.0
			_body.add_child(wheel)
			var stud := BoxMesh.new()
			stud.size = Vector3(0.12, 0.14, 0.24)
			for index in 8:
				var angle := TAU * index / 8.0
				var tread := Mats.mesh(stud, pale, Vector3(cos(angle), sin(angle), 0.0) * 0.47)
				tread.rotation.z = angle - PI / 2.0
				_body.add_child(tread)
		PowerUps.Kind.FLARE:
			# A little sun: a ball with rays.
			var ball := SphereMesh.new()
			ball.radius = 0.24
			ball.height = 0.48
			_body.add_child(Mats.mesh(ball, pale))
			var ray := BoxMesh.new()
			ray.size = Vector3(0.08, 0.2, 0.08)
			for index in 8:
				var angle := TAU * index / 8.0
				var beam := Mats.mesh(ray, lit, Vector3(cos(angle), sin(angle), 0.0) * 0.44)
				beam.rotation.z = angle - PI / 2.0
				_body.add_child(beam)
		PowerUps.Kind.SLOW:
			# Double jump turned over: two triangles pointing down.
			for height: float in [-0.2, 0.2]:
				var triangle := PrismMesh.new()
				triangle.size = Vector3(0.62, 0.4, 0.2)
				var arrow := Mats.mesh(triangle, lit, Vector3.UP * height)
				arrow.rotation.z = PI
				_body.add_child(arrow)
		PowerUps.Kind.DIZZY:
			# A spiral, wound outward from the middle.
			const STEPS := 160
			var path := PackedVector3Array()
			for step in STEPS + 1:
				var along := float(step) / STEPS
				var angle := along * TAU * 2.25
				# Starts a tube's width out from the middle, so the first
				# turn does not fold into itself.
				path.append(Vector3(cos(angle), sin(angle), 0.0) * (0.1 + 0.36 * along))
			# The spiral lies flat in XY, so its rings are squared against Z.
			_body.add_child(Mats.mesh(Mats.tube(path, 0.05, 14, Vector3.BACK), lit))
			# Round off both cut ends.
			var cap := SphereMesh.new()
			cap.radius = 0.05
			cap.height = 0.1
			for end: Vector3 in [path[0], path[STEPS]]:
				_body.add_child(Mats.mesh(cap, lit, end))
		PowerUps.Kind.HEAVY:
			# A scale weight: a squat block with a ring to lift it by.
			var block := CylinderMesh.new()
			block.top_radius = 0.26
			block.bottom_radius = 0.42
			block.height = 0.5
			block.radial_segments = 6
			_body.add_child(Mats.mesh(block, lit, Vector3.UP * -0.12))
			var loop := TorusMesh.new()
			loop.inner_radius = 0.1
			loop.outer_radius = 0.19
			var handle := Mats.mesh(loop, pale, Vector3.UP * 0.26)
			handle.rotation.x = PI / 2.0
			_body.add_child(handle)
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


## A hang glider: a delta wing, a spine along it, and a ball slung beneath.
## Shared with the game, which flies a small one over the marble while the
## power-up runs. The nose points down -Z.
static func build_glider(wing_material: Material, frame_material: Material) -> Node3D:
	var glider := Node3D.new()
	# The wing is a single sheet, seen from underneath as often as above.
	var cloth := wing_material.duplicate() as BaseMaterial3D
	cloth.cull_mode = BaseMaterial3D.CULL_DISABLED
	var nose := Vector3(0.0, 0.12, -0.46)
	var tail := Vector3(0.0, 0.1, 0.22)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Wing tips sit higher than the spine, so the wing reads as a shallow V.
	for corner: Vector3 in [nose, Vector3(-0.62, 0.22, 0.32), tail,
			nose, tail, Vector3(0.62, 0.22, 0.32)]:
		tool.add_vertex(corner)
	tool.generate_normals()
	glider.add_child(Mats.mesh(tool.commit(), cloth))
	var spine := BoxMesh.new()
	spine.size = Vector3(0.05, 0.05, 0.7)
	glider.add_child(Mats.mesh(spine, frame_material, Vector3(0.0, 0.12, -0.12)))
	var strut := BoxMesh.new()
	strut.size = Vector3(0.03, 0.28, 0.03)
	glider.add_child(Mats.mesh(strut, frame_material, Vector3(0.0, -0.03, -0.02)))
	var pilot := SphereMesh.new()
	pilot.radius = 0.12
	pilot.height = 0.24
	glider.add_child(Mats.mesh(pilot, frame_material, Vector3(0.0, -0.2, -0.02)))
	glider.rotation.x = 0.2
	return glider


## A point [param along] (0..1) a helix wound round the Y axis.
func _helix_point(along: float, turns: float, radius: float, height: float) -> Vector3:
	var angle := along * turns * TAU
	return Vector3(cos(angle) * radius, (along - 0.5) * height, sin(angle) * radius)


func _on_body_entered(body: Node3D) -> void:
	if not _available or not body is Marble:
		return
	_available = false
	hide()
	taken.emit(self)
	await get_tree().create_timer(RESPAWN_SECONDS, false).timeout
	_available = true
	show()
