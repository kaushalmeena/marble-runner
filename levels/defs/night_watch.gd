extends LevelDef
## Patrolling rivals and laser beams in the dark, with a flare half way.


func _init() -> void:
	id = &"night_watch_2"
	title = "Night Watch"
	hint = "Guards and beams, and no light but yours."
	biome = preload("res://resources/biomes/night.tres")
	dark = true
	gold_time = 40.0
	silver_time = 63.0


func build(b: LevelBuilder) -> void:
	b.start(Vector3(0, 0, 0))
	b.floor(0, -24, 8, 52)
	b.patroller(Vector3(-3, 0, -10), Vector3(6, 0, 0), 4.0)
	b.gem(Vector3(0, 0, -13))
	b.laser(Vector3(-4, 0, -18), Vector3(4, 0, -18), 1.4, 1.6)
	b.power_up(PowerUps.Kind.FLARE, Vector3(0, 0, -22))
	b.patroller(Vector3(3, 0, -26), Vector3(-6, 0, 0), 3.4)
	b.gem(Vector3(-2, 0, -29))
	b.checkpoint(Vector3(0, 0, -31))
	b.laser(Vector3(-4, 0, -36), Vector3(4, 0, -36), 1.2, 1.8)
	b.gem(Vector3(0, 0, -38))
	b.laser(Vector3(-4, 0, -40), Vector3(4, 0, -40), 1.2, 1.8, 1.5)
	b.patroller(Vector3(-3, 0, -44), Vector3(6, 0, 0), 3.0)
	b.gem(Vector3(2, 0, -46))
	# The finish used to stand here. Now it is a checkpoint, and the level
	# carries on: the second half is laid out as a trail.
	b.checkpoint(Vector3(0, 0, -48))
	var left := Trail.LEFT
	var t := Trail.new(b, Vector3(0, 0, -50), 0)
	t.lasers(3, 4.0)
	t.run(6)
	t.secret_guard()
	t.turn(left)
	t.beam(10, 1)
	t.run(5)
	t.slalom(2)
	t.gap(3)
	t.run(6)
	t.patrol(3.0, 2.8)
	t.lasers(2)
	t.run(5)
	t.finish()
