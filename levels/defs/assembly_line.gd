extends LevelDef
## Beams across a moving belt, a crumbling crossing, then a belt run backwards.


func _init() -> void:
	id = &"assembly_line"
	title = "Assembly Line"
	hint = "The belt will not wait for the beam."
	biome = preload("res://resources/biomes/foundry.tres")
	gold_time = 25.0
	silver_time = 40.0


func build(b: LevelBuilder) -> void:
	b.start(Vector3(0, 0, 0))
	b.floor(0, -3, 6, 10)
	b.floor(0, -20, 4, 24)
	b.conveyor(Vector3(0, 0, -20), Vector2(4, 24), 0, 5)
	b.tip(Vector3(0, 0, -6), "The belt carries you into the beams. Roll back against it to wait.")
	b.laser(Vector3(-2, 0, -16), Vector3(2, 0, -16), 1.2, 1.8)
	b.gem(Vector3(0, 0, -20))
	b.laser(Vector3(-2, 0, -25), Vector3(2, 0, -25), 1.2, 1.8, 1.5)
	b.gem(Vector3(0, 0, -29))

	b.floor(0, -37, 8, 10)
	b.checkpoint(Vector3(0, 0, -35))
	for tile in 3:
		var z := -43.5 - tile * 3.0
		b.crumble(0, z)
		b.gem(Vector3(0, 0, z))
	b.floor(0, -56, 8, 10)
	b.checkpoint(Vector3(0, 0, -54))

	b.floor(0, -69, 4, 16)
	b.conveyor(Vector3(0, 0, -69), Vector2(4, 16), 180, 4)
	b.laser(Vector3(-2, 0, -69), Vector3(2, 0, -69), 1.0, 2.0)
	b.gem(Vector3(0, 0, -73))
	b.floor(0, -82, 8, 10)
	b.finish_at(Vector3(0, 0, -83))
