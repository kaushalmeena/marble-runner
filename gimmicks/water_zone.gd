class_name WaterZone
extends Area3D
## A body of water. Inside it the marble sinks slowly, loses speed, and swims
## upward with the jump key.

const COLOR := Color(0.2, 0.55, 0.95)


func _init(size := Vector3(8.0, 4.0, 8.0)) -> void:
	collision_layer = 0
	collision_mask = 2
	var shape := BoxShape3D.new()
	shape.size = size
	add_child(Mats.collider(shape))

	var volume := BoxMesh.new()
	volume.size = size
	var water := StandardMaterial3D.new()
	water.albedo_color = Color(COLOR, 0.32)
	water.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water.roughness = 0.1
	water.cull_mode = BaseMaterial3D.CULL_DISABLED
	var body := Mats.mesh(volume, water)
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(body)
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
