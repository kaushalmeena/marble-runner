extends LevelDef
## The first heavy-gravity level: low steps, a short gap, and a bounce pad up a cliff.


func _init() -> void:
	id = &"heavy_metal"
	title = "Heavy Metal"
	hint = "Everything weighs more here. So do you."
	biome = preload("res://resources/biomes/foundry.tres")
	gravity_scale = 1.4
	gold_time = 18.0
	silver_time = 29.0


func build(b: LevelBuilder) -> void:
	var floor_kind := LevelBuilder.Surface.FLOOR
	b.start(Vector3(0, 0, 0))
	# The secret diamond: on a ledge behind and below the start.
	b.secret_ledge(Vector3(0, -2, 5))
	b.floor(0, -6, 8, 16)
	b.tip(Vector3(0, 0, -3), "Heavy gravity. Your jumps are low and short.")
	b.gem(Vector3(0, 0, -10))
	b.floor(0, -18, 8, 8, 0.6, floor_kind, 1.6)
	b.gem(Vector3(0, 0.6, -18))
	b.floor(0, -26, 8, 8, 1.2, floor_kind, 2.2)
	b.gem(Vector3(0, 1.2, -26))
	b.floor(0, -36.5, 8, 10, 1.2, floor_kind, 2.2)
	b.checkpoint(Vector3(0, 1.2, -34))
	b.tip(Vector3(0, 1.2, -36), "Too high to jump. The pad will throw you.")
	b.bounce_pad(Vector3(0, 1.2, -40.2), 15.0)
	b.floor(0, -47, 8, 11, 4.0, floor_kind, 5.0)
	b.gem(Vector3(0, 4, -45))
	b.finish_at(Vector3(0, 4, -50))
