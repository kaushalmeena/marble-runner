class_name BoostPad
extends Area3D
## A strip that flings the marble along its arrow.

## Speed the marble leaves at, along the pad's forward (-Z) axis.
var speed: float = 20.0

var _material: StandardMaterial3D
var _time: float = 0.0


func _init(launch_speed: float = 20.0) -> void:
	speed = launch_speed
	collision_layer = 0
	collision_mask = 2
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.4, 1.2, 3.0)
	add_child(Mats.collider(shape, Vector3.UP * 0.6))

	var plate := BoxMesh.new()
	plate.size = Vector3(2.4, 0.06, 3.0)
	add_child(Mats.mesh(plate, Mats.solid(Color(0.08, 0.12, 0.14), 0.4), Vector3.UP * 0.03))
	_material = Mats.glow(Color(0.3, 1.0, 0.6), 1.6)
	for index in 3:
		var arrow := PrismMesh.new()
		arrow.size = Vector3(1.5, 0.7, 0.05)
		var chevron := Mats.mesh(arrow, _material, Vector3(0.0, 0.09, 0.95 - index * 0.95))
		# A prism stands upright; laid flat it becomes an arrowhead pointing -Z.
		chevron.rotation.x = -PI / 2.0
		add_child(chevron)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	_material.emission_energy_multiplier = 1.4 + 0.6 * sin(_time * 8.0)


func _on_body_entered(body: Node3D) -> void:
	var marble := body as Marble
	if marble == null:
		return
	# Aligned: a pad crossed at an angle still fires straight down its arrow,
	# rather than adding its speed to whatever sideways drift came in.
	marble.boost(-global_basis.z, speed, true)
	Audio.play(&"boost", -4.0, 0.05)
