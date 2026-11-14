extends LevelDef
## Beams across a moving belt, a crumbling crossing, then a belt run backwards.


func _init() -> void:
	id = &"assembly_line_2"
	title = "Assembly Line"
	hint = "The belt will not wait for the beam."
	biome = preload("res://resources/biomes/foundry.tres")
	gold_time = 46.0
	silver_time = 72.0


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
	# The finish used to stand here. Now it is a checkpoint, and the level
	# carries on: the second half is laid out as a trail.
	b.checkpoint(Vector3(0, 0, -83))
	var right := Trail.RIGHT
	var t := Trail.new(b, Vector3(0, 0, -87), 0)
	t.belt(12)
	t.lasers(2)
	t.turn(right)
	t.belt(12, true)
	t.run(5)
	t.secret_below(Trail.LEFT)
	t.crumbles(4)
	t.run(5)
	t.bridge(12, 5.0, 2)
	t.run(5)
	t.lasers(3, 4.0)
	t.finish()
