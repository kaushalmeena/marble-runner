class_name Portal
extends Area3D
## One end of a pair of doors. Going in one comes out of the other, at the
## same speed, heading the way the exit faces.

## The marble came out of [param exit]. For the camera.
signal used(exit: Portal)

## Seconds an exit ignores the marble after delivering it, so it is not sent
## straight back.
const COOLDOWN := 0.8
## Slowest the marble leaves at, so it never stalls in the doorway.
const MIN_EXIT_SPEED := 5.0
const RING_HEIGHT := 1.15

var partner: Portal = null

var _cooldown: float = 0.0
var _disc: MeshInstance3D
var _time: float = 0.0


func _init(color: Color = Color(0.3, 0.8, 1.0)) -> void:
	collision_layer = 0
	collision_mask = 2
	var shape := CylinderShape3D.new()
	shape.radius = 0.95
	shape.height = 0.7
	var hole := Mats.collider(shape, Vector3.UP * RING_HEIGHT)
	hole.rotation.x = PI / 2.0
	add_child(hole)

	var ring := TorusMesh.new()
	ring.inner_radius = 1.0
	ring.outer_radius = 1.25
	ring.rings = 32
	var frame := Mats.mesh(ring, Mats.glow(color, 1.6), Vector3.UP * RING_HEIGHT)
	frame.rotation.x = PI / 2.0
	add_child(frame)
	var film := CylinderMesh.new()
	film.top_radius = 1.0
	film.bottom_radius = 1.0
	film.height = 0.04
	_disc = Mats.mesh(film, Mats.ghost(color, 0.35), Vector3.UP * RING_HEIGHT)
	_disc.rotation.x = PI / 2.0
	_disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_disc)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	_cooldown = maxf(0.0, _cooldown - delta)
	_disc.scale = Vector3.ONE * (0.92 + 0.08 * sin(_time * 3.0))


## The way the marble is thrown out of this door.
func exit_direction() -> Vector3:
	return -global_basis.z


func _on_body_entered(body: Node3D) -> void:
	var marble := body as Marble
	if marble == null or partner == null or _cooldown > 0.0:
		return
	partner._cooldown = COOLDOWN
	var out := partner.exit_direction()
	var exit_speed := maxf(marble.linear_velocity.length(), MIN_EXIT_SPEED)
	marble.teleport(
		partner.global_position + Vector3.UP * RING_HEIGHT + out * 1.1, out * exit_speed)
	Audio.play(&"boost", -5.0, 0.0, 1.5)
	used.emit(partner)
