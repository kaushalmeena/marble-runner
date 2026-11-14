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
	# Darker underneath than it glows: lit albedo plus emission of the same
	# colour adds up to white, and every gimmick ends up the same pastel.
	var material := solid(color.darkened(0.35), 0.35)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy * 0.5
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


## A round tube following [param path], as one mesh with smooth normals.
##
## For anything that curves: built from separate straight pieces, a curve
## shows a ridge at every joint. The path must not run straight up or down.
static func tube(path: PackedVector3Array, radius: float, sides: int = 10) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count := path.size()
	for index in count:
		# Direction of travel, averaged across the point so the rings on
		# either side of it meet without a crease.
		var ahead := path[mini(index + 1, count - 1)] - path[maxi(index - 1, 0)]
		var tangent := ahead.normalized()
		var side := (Vector3.UP - tangent * Vector3.UP.dot(tangent)).normalized()
		var other := tangent.cross(side)
		for corner in sides:
			var angle := TAU * corner / sides
			var normal := side * cos(angle) + other * sin(angle)
			tool.set_normal(normal)
			tool.add_vertex(path[index] + normal * radius)
	for index in count - 1:
		for corner in sides:
			var a := index * sides + corner
			var b := index * sides + (corner + 1) % sides
			var c := a + sides
			var d := b + sides
			tool.add_index(a)
			tool.add_index(c)
			tool.add_index(b)
			tool.add_index(b)
			tool.add_index(c)
			tool.add_index(d)
	return tool.commit()
