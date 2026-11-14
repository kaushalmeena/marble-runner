extends LevelDef
## The first open level: no path, just ten gems and a locked finish in the
## middle. Teaches that the order is the player's to choose.


func _init() -> void:
	id = &"gem_garden"
	title = "Gem Garden"
	hint = "Ten gems, any order you like."
	biome = preload("res://resources/biomes/desert.tres")
	gold_time = 30.0
	silver_time = 50.0


func build(b: LevelBuilder) -> void:
	b.start(Vector3(0, 0, 13))
	b.tip(Vector3(0, 0, 13), "The finish is in the middle. It opens when the last gem is yours.")
	b.floor(0, 0, 32, 32)
	b.wall(Vector3(-15.8, 0, -15.8), Vector3(15.8, 0, -15.8))
	b.wall(Vector3(-15.8, 0, 15.8), Vector3(15.8, 0, 15.8))
	b.wall(Vector3(-15.8, 0, -15.8), Vector3(-15.8, 0, 15.8))
	b.wall(Vector3(15.8, 0, -15.8), Vector3(15.8, 0, 15.8))
	b.floor(0, 0, 8, 8, 1.0, LevelBuilder.Surface.WALL)
	b.finish_at(Vector3(0, 1, 0))

	for corner: Vector2 in [Vector2(-13, -13), Vector2(13, -13), Vector2(-13, 13), Vector2(13, 13)]:
		b.gem(Vector3(corner.x, 0, corner.y))
	b.gem(Vector3(0, 0, -13))

	# A raised walkway across the back, with a ramp up at either end.
	b.ramp(Vector3(10, 0, 6), Vector3(10, 3, -5), 4)
	b.floor(10, -8, 6, 6, 3, LevelBuilder.Surface.FLOOR, 0.5)
	b.floor(0, -8, 14, 2, 3, LevelBuilder.Surface.FLOOR, 0.5)
	b.floor(-10, -8, 6, 6, 3, LevelBuilder.Surface.FLOOR, 0.5)
	b.ramp(Vector3(-10, 0, 6), Vector3(-10, 3, -5), 4)
	b.gem_line(Vector3(-10, 3, -8), Vector3(10, 3, -8), 5)
