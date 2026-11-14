class_name Fan
extends Area3D
## A column of rising air.
##
## The lift is strongest at the grille and fades to nothing at the top of the
## column, so the marble settles at a hover height rather than being fired out
## of the top. Halfway up is where lift equals gravity.

## Lift at the grille, as a multiple of gravity.
const LIFT_AT_BASE := 2.0
## Bleeds off vertical speed inside the column, so the hover settles instead of
## bouncing for ever.
const DAMPING := 1.6

var height: float = 12.0

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _init(column_height: float = 12.0, radius: float = 1.8) -> void:
	height = column_height
	collision_layer = 0
	collision_mask = 2
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	add_child(Mats.collider(shape, Vector3.UP * height / 2.0))

	var grille := CylinderMesh.new()
	grille.top_radius = radius
	grille.bottom_radius = radius * 0.8
	grille.height = 0.4
	add_child(Mats.mesh(grille, Mats.solid(Color(0.16, 0.2, 0.28), 0.4, 0.7), Vector3.UP * 0.2))

	var column := CylinderMesh.new()
	column.top_radius = radius * 0.9
	column.bottom_radius = radius
	column.height = height
	column.cap_top = false
	column.cap_bottom = false
	var air := Mats.mesh(column, Mats.ghost(Color(0.7, 0.92, 1.0), 0.07), Vector3.UP * height / 2.0)
	air.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(air)

	var streaks := CPUParticles3D.new()
	streaks.amount = 16
	streaks.lifetime = height / 9.0
	streaks.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	streaks.emission_sphere_radius = radius * 0.8
	streaks.direction = Vector3.UP
	streaks.spread = 2.0
	streaks.gravity = Vector3.ZERO
	streaks.initial_velocity_min = 8.0
	streaks.initial_velocity_max = 10.0
	var streak := BoxMesh.new()
	streak.size = Vector3(0.03, 0.5, 0.03)
	streak.material = Mats.ghost(Color(0.85, 0.97, 1.0), 0.16)
	streaks.mesh = streak
	streaks.position = Vector3.UP * 0.4
	add_child(streaks)


func _physics_process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		var marble := body as Marble
		if marble == null:
			continue
		var above := clampf((marble.global_position.y - global_position.y) / height, 0.0, 1.0)
		# Scaled by the marble's own gravity, so the hover height is the same
		# on the moon or under an umbrella as anywhere else.
		var lift := _gravity * marble.gravity_scale * LIFT_AT_BASE * (1.0 - above)
		marble.apply_central_force(Vector3.UP * marble.mass * (
			lift - marble.linear_velocity.y * DAMPING))
