class_name BurstEmitter
extends Node3D
## A small ring of one-shot particle bursts, reused round-robin.
##
## Pickups can land closer together than one burst lasts, so a single emitter
## would cut itself short. A handful of pre-built children costs nothing and
## means a burst is never interrupted, and nothing is allocated mid-run.

## CPUParticles3D rather than GPU: the project targets the Compatibility
## renderer for the web export, and these bursts are far too small to be worth
## the extra requirements.
@export var burst_count: int = 4
@export var particle_amount: int = 14
@export var lifetime: float = 0.55

var _emitters: Array[CPUParticles3D] = []
var _next: int = 0


func _ready() -> void:
	for _i in burst_count:
		var particles := CPUParticles3D.new()
		particles.emitting = false
		particles.one_shot = true
		particles.explosiveness = 1.0
		particles.amount = particle_amount
		particles.lifetime = lifetime
		particles.mesh = _build_mesh()
		particles.direction = Vector3.UP
		particles.spread = 65.0
		particles.initial_velocity_min = 3.0
		particles.initial_velocity_max = 6.5
		particles.gravity = Vector3(0.0, -12.0, 0.0)
		particles.scale_amount_min = 0.7
		particles.scale_amount_max = 1.3
		particles.scale_amount_curve = _build_shrink_curve()
		add_child(particles)
		_emitters.append(particles)


## Fires a burst at [param world_position] in [param color].
func burst(world_position: Vector3, color: Color) -> void:
	if _emitters.is_empty():
		return
	var particles := _emitters[_next]
	_next = (_next + 1) % _emitters.size()
	particles.global_position = world_position
	particles.color = color
	particles.restart()


func _build_mesh() -> Mesh:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.16, 0.16, 0.16)
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material = material
	return mesh


func _build_shrink_curve() -> Curve:
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	return curve
