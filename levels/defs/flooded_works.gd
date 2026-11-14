extends LevelDef
## A flooded hall: beams on the bottom and half way up, a rising guard, and a key for the gate out.


func _init() -> void:
	id = &"flooded_works_2"
	title = "Flooded Works"
	hint = "The beams still work under water."
	biome = preload("res://resources/biomes/reef.tres")
	gold_time = 62.0
	silver_time = 97.0


func build(b: LevelBuilder) -> void:
	var floor_kind := LevelBuilder.Surface.FLOOR
	var wall := LevelBuilder.Surface.WALL
	b.start(Vector3(0, 0, 0))
	b.floor(0, -2, 12, 8, 0, floor_kind, 8.5)
	b.floor(0, -21, 12, 30, -8)
	b.box(Vector3(-6.25, -3.4, -26), Vector3(0.5, 10.2, 40), wall)
	b.box(Vector3(6.25, -3.4, -26), Vector3(0.5, 10.2, 40), wall)
	b.water(Vector3(0, -4, -26), Vector3(12, 8, 40))
	b.tip(Vector3(0, 0, -1), "The key is on the bottom. So are the beams.")
	b.laser(Vector3(-6, -8, -14), Vector3(6, -8, -14), 1.5, 2.0)
	b.gem(Vector3(-3, -8, -18))
	b.laser(Vector3(-6, -5, -21), Vector3(6, -5, -21), 1.5, 2.0, 1.75)
	b.gem(Vector3(3, -5, -24))
	b.patroller(Vector3(0, -7.5, -27), Vector3(0, 5, 0), 4.0)
	b.key(Vector3(0, -8, -31))
	b.gem(Vector3(-4, -8, -32))
	b.ramp(Vector3(0, -8, -36), Vector3(0, 0, -46), 12)
	b.floor(0, -52, 12, 12, 0, floor_kind, 8.5)
	b.checkpoint(Vector3(0, 0, -47.5))
	b.gate(Vector3(0, 0, -50), 12)
	# The finish used to stand here. Now it is a checkpoint, and the level
	# carries on: the second half is laid out as a trail.
	b.checkpoint(Vector3(0, 0, -55))
	var left := Trail.LEFT
	var t := Trail.new(b, Vector3(0, 0, -58), 0)
	t.run(6, 1)
	t.lasers(3, 4.0)
	t.turn(left)
	t.belt(10, true)
	t.run(5)
	t.beam(10, 1)
	t.run(6)
	t.patrol()
	t.slalom(2)
	t.run(5)
	t.finish()
