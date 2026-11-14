class_name Mats
extends RefCounted
## Small factory for the materials the gimmicks build themselves with.
##
## Gimmicks are assembled in code rather than authored as scenes, so they all
## need the same three kinds of material. Keeping them here keeps the look
## consistent and the gimmick scripts about behaviour.


## Opaque and matte-to-glossy.
static func solid(color: Color, roughness: float = 0.6, metallic: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material


## Opaque and self-lit, bright enough to bloom.
static func glow(color: Color, energy: float = 1.6) -> StandardMaterial3D:
	var material := solid(color, 0.35)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material


## See-through and unlit, for beams, bubbles and airflow.
static func ghost(color: Color, alpha: float = 0.25) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color, alpha)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	return material


## A mesh instance with one material, placed at [param position].
static func mesh(shape: Mesh, material: Material, position := Vector3.ZERO) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = shape
	instance.material_override = material
	instance.position = position
	return instance


## A collision shape node at [param position].
static func collider(shape: Shape3D, position := Vector3.ZERO) -> CollisionShape3D:
	var node := CollisionShape3D.new()
	node.shape = shape
	node.position = position
	return node
