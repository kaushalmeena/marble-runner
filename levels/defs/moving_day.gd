extends LevelDef
## Moving platforms: a ferry, a sideways ferry, a lift, then two in a row with
## a hop between them.


func _init() -> void:
	id = &"moving_day"
	title = "Moving Day"
	hint = "The platforms will not wait. Neither should you."
	biome = preload("res://resources/biomes/tundra.tres")
	gold_time = 34.0
	silver_time = 55.0


func build(b: LevelBuilder) -> void:
	var pad := Vector2(4, 4)
	b.start(Vector3(0, 0, 0))
	b.tip(Vector3(0, 0, 0), "Platforms pause at each end. Board them there.")
	b.floor(0, -2, 6, 8)
	b.mover(Vector3(0, 0, -8.2), pad, Vector3(0, 0, -9), 6.0)
	b.gem(Vector3(0, 0, -12.7))

	b.floor(0, -23.4, 6, 8)
	b.checkpoint(Vector3(0, 0, -22))
	b.gem(Vector3(0, 0, -25.5))
	b.mover(Vector3(-5.2, 0, -23.4), pad, Vector3(-9, 0, 0), 6.0, 0.5)
	b.gem(Vector3(-9.7, 0, -23.4))

	b.floor(-20.4, -23.4, 8, 8)
	b.gem(Vector3(-22.4, 0, -21.4))
	b.mover(Vector3(-20.4, 0, -29.6), pad, Vector3(0, 5, 0), 7.0)
	b.tip(Vector3(-20.4, 0, -25.5), "This one is a lift.")

	b.floor(-20.4, -36.8, 8, 10, 5, LevelBuilder.Surface.FLOOR, 0.5)
	b.checkpoint(Vector3(-20.4, 5, -34))
	b.gem(Vector3(-20.4, 5, -39))
	b.mover(Vector3(-20.4, 5, -44), pad, Vector3(0, 0, -8), 5.0)
	b.mover(Vector3(-24.4, 5, -58.2), pad, Vector3(8, 0, 0), 4.5)
	b.gem(Vector3(-20.4, 5, -58.2))

	b.floor(-20.4, -66.4, 8, 12, 5, LevelBuilder.Surface.FLOOR, 0.5)
	b.finish_at(Vector3(-20.4, 5, -68.5))
