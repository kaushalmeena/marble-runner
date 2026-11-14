extends LevelDef
## The last level: the longest course, every mechanic, and checkpoints few and far between.


func _init() -> void:
	id = &"grand_tour"
	title = "Grand Tour"
	hint = "The whole game in one run. Good luck."
	biome = preload("res://resources/biomes/canyon.tres")
	gold_time = 78.0
	silver_time = 119.0


func build(b: LevelBuilder) -> void:
	var left := Trail.LEFT
	var right := Trail.RIGHT
	var t := Trail.new(b)
	t.start()
	t.run(6, 1)
	t.slalom(3)
	t.gap(3.5)
	t.run(5)
	t.step(0.8)
	t.run(5)
	t.step(0.8)
	t.run(6)
	t.checkpoint()
	t.turn(left)
	t.beam(14, 2, 1.6)
	t.run(5)
	t.bridge(14, 5.0, 2)
	t.run(6)
	t.crumbles(5)
	t.run(6)
	t.turn(right)
	t.ramp(12, 4)
	t.run(6)
	t.checkpoint()
	t.lasers(3, 4.0)
	t.belt(12, true)
	t.run(5)
	t.bounce(3)
	t.run(8)
	t.patrol()
	t.turn(right)
	t.fan(5)
	t.run(9, 1)
	t.glide(22, 7)
	t.run(12, 1)
	t.checkpoint()
	t.turn(left)
	t.power(PowerUps.Kind.SHIELD)
	t.arena(16, 8, 2)
	t.run(7)
	t.cannon(28, 5)
	t.run(18, 1)
	t.sentry(2.0, 6.0)
	t.beam(12, 1, 1.5)
	t.run(5)
	t.mover(10)
	t.run(7)
	t.glide(18, 4)
	t.run(10)
	t.crumbles(4)
	t.run(5)
	t.finish()
