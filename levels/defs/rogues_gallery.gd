extends LevelDef
## Three arenas of chasers joined by corridors of patrols, sentries and traps.


func _init() -> void:
	id = &"rogues_gallery"
	title = "Rogues"
	hint = "Every kind of rival, and more of them each time."
	biome = preload("res://resources/biomes/storm.tres")
	gold_time = 49.0
	silver_time = 75.0


func build(b: LevelBuilder) -> void:
	var left := Trail.LEFT
	var right := Trail.RIGHT
	var t := Trail.new(b)
	t.start()
	t.run(8)
	t.power(PowerUps.Kind.SHIELD)
	t.arena(14, 6, 1)
	t.run(8)
	t.patrol()
	t.checkpoint()
	t.turn(right)
	t.run(12, 2)
	t.sentry(2.0, 8.0)
	t.sentry(-2.0, 3.0)
	t.slalom(2)
	t.turn(left)
	t.arena(16, 8, 2)
	t.run(10)
	t.trap(PowerUps.Kind.DIZZY, 1.5, 3.0)
	t.trap(PowerUps.Kind.SLOW, -1.5, 6.0)
	t.checkpoint()
	t.beam(10, 1)
	t.run(8)
	t.patrol(3.0, 2.6)
	t.run(8, 1)
	t.power(PowerUps.Kind.SHIELD)
	t.arena(14, 6, 2)
	t.run(8)
	t.sentry(0.0, 4.0)
	t.finish()
