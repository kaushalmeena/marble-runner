extends LevelDef
## Low gravity. The same jump goes three times as high and stays up for two
## seconds, which makes every gap easy and every landing a decision.


func _init() -> void:
	id = &"moonwalk"
	title = "Moonwalk"
	hint = "Everything floats. So do your mistakes."
	biome = preload("res://resources/biomes/moon.tres")
	gravity_scale = 0.35
	gold_time = 30.0
	silver_time = 50.0


func build(b: LevelBuilder) -> void:
	var thin := 0.5
	var floor_kind := LevelBuilder.Surface.FLOOR
	b.start(Vector3(0, 0, 0))
	# The secret diamond: on a ledge behind and below the start.
	b.secret_ledge(Vector3(0, -3, 6))
	b.tip(Vector3(0, 0, 0), "Low gravity. Jumps go a long way, so ease off early.")
	b.floor(0, -3, 8, 10)
	b.floor(0, -23, 8, 10)
	b.gem(Vector3(0, 0, -21))
	b.gem(Vector3(0, 0, -25))
	b.floor(0, -36, 8, 10, 3, floor_kind, 4)
	b.checkpoint(Vector3(0, 3, -33))
	b.gem(Vector3(2.5, 3, -35))
	b.power_up(PowerUps.Kind.DOUBLE_JUMP, Vector3(0, 3, -37))
	b.tip(Vector3(0, 3, -35), "That ledge is too high for one jump, even here.")

	b.floor(0, -62, 10, 12, 8, floor_kind, thin)
	b.checkpoint(Vector3(0, 8, -59))
	b.gem(Vector3(0, 8, -64))
	b.floor(10, -62, 5, 5, 6, floor_kind, thin)
	b.gem(Vector3(10, 6, -62))
	b.floor(19, -62, 5, 5, 4, floor_kind, thin)
	b.gem(Vector3(19, 4, -62))
	b.floor(28, -62, 5, 5, 2, floor_kind, thin)
	b.gem(Vector3(28, 2, -62))
	b.floor(39, -62, 10, 10, 0, floor_kind, thin)
	b.finish_at(Vector3(40, 0, -62))
