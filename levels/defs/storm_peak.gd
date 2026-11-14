extends LevelDef
## The finale: a belt through beams, a timed bridge, a chaser on the key, and a windy climb over falling stones.


func _init() -> void:
	id = &"storm_peak_2"
	title = "Storm Peak"
	hint = "The top of the mountain, and all of it at once."
	biome = preload("res://resources/biomes/storm.tres")
	wind = Vector3(2.5, 0.0, 0.0)
	gold_time = 62.0
	silver_time = 97.0


func build(b: LevelBuilder) -> void:
	b.start(Vector3(0, 0, 0))
	b.floor(0, -4, 8, 12)
	b.floor(0, -16, 4, 12)
	b.conveyor(Vector3(0, 0, -16), Vector2(4, 12), 0, 5)
	b.laser(Vector3(-2, 0, -14), Vector3(2, 0, -14), 1.2, 1.8)
	b.gem(Vector3(0, 0, -17))
	b.laser(Vector3(-2, 0, -20), Vector3(2, 0, -20), 1.2, 1.8, 1.5)

	b.floor(0, -27, 8, 10)
	b.checkpoint(Vector3(0, 0, -24.5))
	b.power_up(PowerUps.Kind.SHIELD, Vector3(-2.5, 0, -27))
	var span := b.bridge(0, -39, 4, 14)
	b.button(Vector3(0, 0, -29.5), [span], 6.0)
	b.gem_line(Vector3(0, 0, -35), Vector3(0, 0, -43), 3)

	b.floor(0, -52, 10, 12)
	b.checkpoint(Vector3(0, 0, -48))
	b.chaser(Vector3(0, 0, -53), 6.0, 4.0)
	b.key(Vector3(3.5, 0, -54))
	b.gate(Vector3(0, 0, -57), 10)
	b.ramp(Vector3(0, 0, -58), Vector3(0, 4, -70), 6)
	b.floor(0, -76, 8, 12, 4)
	b.checkpoint(Vector3(0, 4, -72))
	b.trap(PowerUps.Kind.DIZZY, Vector3(-2.5, 4, -77))
	b.trap(PowerUps.Kind.HEAVY, Vector3(2.5, 4, -77))
	b.gem(Vector3(0, 4, -77))
	b.crumble(0, -83.5, 4)
	b.gem(Vector3(0, 4, -83.5))
	b.crumble(0, -86.5, 4)
	b.floor(0, -93, 8, 10, 4)
	# The finish used to stand here. Now it is a checkpoint, and the level
	# carries on: the second half is laid out as a trail.
	b.checkpoint(Vector3(0, 4, -95))
	var left := Trail.LEFT
	var right := Trail.RIGHT
	var t := Trail.new(b, Vector3(0, 4, -98), 0)
	t.lasers(2)
	t.belt(10, true)
	t.run(5)
	t.turn(right)
	t.bridge(14, 5.5, 2)
	t.run(6)
	t.secret_guard()
	t.turn(left)
	t.beam(12, 2, 2.0)
	t.run(5)
	t.crumbles(4)
	t.run(5)
	t.step(0.8)
	t.run(5)
	t.slalom(2)
	t.run(4)
	t.finish()
