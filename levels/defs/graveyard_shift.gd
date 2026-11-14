extends LevelDef
## The course finale: a belt through a beam, a timed bridge, a sentry and a cannon, all in the dark.


func _init() -> void:
	id = &"graveyard_shift_2"
	title = "Graveyard"
	hint = "Everything on the night shift, with the lights off."
	biome = preload("res://resources/biomes/night.tres")
	dark = true
	gold_time = 51.0
	silver_time = 80.0


func build(b: LevelBuilder) -> void:
	b.start(Vector3(0, 0, 0))
	b.floor(0, -4, 8, 12)
	b.floor(0, -16, 4, 12)
	b.conveyor(Vector3(0, 0, -16), Vector2(4, 12), 0, 5)
	b.laser(Vector3(-2, 0, -16), Vector3(2, 0, -16), 1.2, 1.8)
	b.gem(Vector3(0, 0, -20))

	b.floor(0, -27, 8, 10)
	b.checkpoint(Vector3(0, 0, -24.5))
	b.power_up(PowerUps.Kind.FLARE, Vector3(3, 0, -27))
	var span := b.bridge(0, -39, 4, 14)
	b.button(Vector3(0, 0, -29.5), [span], 6.0)
	b.gem_line(Vector3(0, 0, -35), Vector3(0, 0, -43), 3)

	b.floor(0, -52, 10, 12)
	b.checkpoint(Vector3(0, 0, -48))
	b.power_up(PowerUps.Kind.SHIELD, Vector3(-3.5, 0, -50))
	b.sentry(Vector3(3.5, 0, -54), 11.0)
	b.cannon(Vector3(0, 0, -56), Vector3(0, 6, -84), 2.2)

	b.floor(0, -90, 10, 18, 6)
	b.patroller(Vector3(-4, 6, -90), Vector3(8, 0, 0), 3.6)
	b.gem(Vector3(0, 6, -87))
	# The finish used to stand here. Now it is a checkpoint, and the level
	# carries on: the second half is laid out as a trail.
	b.checkpoint(Vector3(0, 6, -95))
	var right := Trail.RIGHT
	var t := Trail.new(b, Vector3(0, 6, -99), 0)
	t.run(6)
	t.lasers(2)
	t.belt(10, true)
	t.run(5)
	t.turn(right)
	t.bridge(14, 5.5, 2)
	t.run(6)
	t.patrol()
	t.glide(18, 5)
	t.run(10, 1)
	t.slalom(2)
	t.crumbles(3)
	t.run(6)
	t.sentry(2.0, 3.0)
	t.finish()
