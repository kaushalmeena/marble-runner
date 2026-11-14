class_name WaterZone
extends Area3D
## A body of water. Inside it the marble sinks slowly, loses speed, and swims
## upward with the jump key.

const COLOR := Color(0.2, 0.55, 0.95)
const SURFACE_SHADER := preload("res://world/water.gdshader")
const SURFACE_DROP := 0.08
const SURFACE_INSET := 0.04


func _init(size := Vector3(8.0, 4.0, 8.0)) -> void:
	collision_layer = 0
	collision_mask = 2
	var shape := BoxShape3D.new()
	shape.size = size
	add_child(Mats.collider(shape))

	# Only the surface is drawn, a touch below the rim and a touch inside the
	# walls, so it never shares a plane with the floor around the pool.
	var sheet := PlaneMesh.new()
	sheet.size = Vector2(size.x - SURFACE_INSET, size.z - SURFACE_INSET)
	var material := ShaderMaterial.new()
	material.shader = SURFACE_SHADER
	var surface := Mats.mesh(sheet, material, Vector3.UP * (size.y / 2.0 - SURFACE_DROP))
	surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(surface)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	var marble := body as Marble
	if marble == null:
		return
	marble.enter_water()
	Audio.play(&"land", -4.0, 0.1, 0.6)


func _on_body_exited(body: Node3D) -> void:
	var marble := body as Marble
	if marble != null:
		marble.exit_water()
