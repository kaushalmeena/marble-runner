extends LevelDef
## Introduces the power-up slot with the super jump, then the bounce pad.


func _init() -> void:
	id = &"high_hopes"
	title = "High Hopes"
	hint = "Some walls are too tall to jump. Almost."
	biome = preload("res://resources/biomes/desert.tres")
	gold_time = 24.0
	silver_time = 42.0


func build(b: LevelBuilder) -> void:
	b.start(Vector3(0, 0, 0))
	b.floor(0, -3, 8, 10)
	b.power_up(PowerUps.Kind.SUPER_JUMP, Vector3(0, 0, -4))
	b.tip(Vector3(0, 0, -2), "Power-ups wait in your slot. SHIFT spends the one you hold.")

	b.floor(0, -13, 8, 10, 3, LevelBuilder.Surface.FLOOR, 4)
	b.gem(Vector3(-2, 3, -11))
	b.gem(Vector3(2, 3, -11))
	b.bounce_pad(Vector3(0, 3, -15.5), 16)
	b.tip(Vector3(0, 3, -12), "Keep holding forward while you are in the air.")

	b.floor(0, -25, 8, 8, 7, LevelBuilder.Surface.FLOOR, 0.5)
	b.checkpoint(Vector3(0, 7, -23.5))
	b.gem(Vector3(0, 7, -27))
	b.floor(10, -25, 6, 6, 5, LevelBuilder.Surface.FLOOR, 0.5)
	b.gem(Vector3(10, 5, -25))
	b.floor(19, -25, 6, 6, 3, LevelBuilder.Surface.FLOOR, 0.5)
	b.power_up(PowerUps.Kind.SUPER_JUMP, Vector3(19, 3, -25))

	b.floor(29, -25, 8, 8, 6, LevelBuilder.Surface.FLOOR, 4)
	b.gem(Vector3(27, 6, -23))
	b.gem(Vector3(27, 6, -27))
	b.finish_at(Vector3(30, 6, -25))
