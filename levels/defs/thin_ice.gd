extends LevelDef
## Ice: the marble keeps its speed and ignores the brakes. A walled lane to
## learn on, then an open sheet where over-steering has consequences.


func _init() -> void:
	id = &"thin_ice"
	title = "Thin Ice"
	hint = "On ice you steer early or not at all."
	biome = preload("res://resources/biomes/tundra.tres")
	gold_time = 30.0
	silver_time = 52.0


func build(b: LevelBuilder) -> void:
	var ice := LevelBuilder.Surface.ICE
	b.start(Vector3(0, 0, 0))
	b.floor(0, -2, 8, 8)
	b.power_up(PowerUps.Kind.MAGNET, Vector3(0, 0, -4))
	b.tip(Vector3(0, 0, -1), "Pale floor is ice. Take the MAGNET: gems come to you.")

	b.floor(0, -16, 10, 20, 0, ice)
	b.wall(Vector3(-4.8, 0, -6), Vector3(-4.8, 0, -35.8))
	b.wall(Vector3(4.8, 0, -6), Vector3(4.8, 0, -26))
	for spot: Vector2 in [Vector2(-3, -10), Vector2(3, -14), Vector2(-3, -18), Vector2(3, -22)]:
		b.gem(Vector3(spot.x, 0, spot.y))

	b.floor(9, -31, 28, 10, 0, ice)
	b.wall(Vector3(-4.8, 0, -35.8), Vector3(23, 0, -35.8))
	b.bumper(Vector3(6, 0, -30))
	b.bumper(Vector3(14, 0, -33))
	b.gem(Vector3(2, 0, -32))
	b.gem(Vector3(10, 0, -29.5))
	b.gem(Vector3(18, 0, -32))

	b.floor(27, -31, 8, 2)
	b.checkpoint(Vector3(25.5, 0, -31))
	b.floor(38, -31, 14, 14, 0, ice)
	b.wall(Vector3(31, 0, -37.8), Vector3(44.8, 0, -37.8))
	b.wall(Vector3(44.8, 0, -37.8), Vector3(44.8, 0, -24.2))
	b.wall(Vector3(31, 0, -24.2), Vector3(44.8, 0, -24.2))
	b.gem(Vector3(35, 0, -27))
	b.gem(Vector3(42, 0, -35))
	b.gem(Vector3(42, 0, -27))
	b.finish_at(Vector3(39, 0, -31))
