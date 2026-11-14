extends LevelDef
## Machinery end to end: belts with and against, beam rows, two timed bridges and a platform ride.


func _init() -> void:
	id = &"clockwork_yard"
	title = "The Works"
	hint = "Belts, beams and bridges, all on their own clocks."
	biome = preload("res://resources/biomes/foundry.tres")
	gold_time = 43.0
	silver_time = 65.0


func build(b: LevelBuilder) -> void:
	var left := Trail.LEFT
	var right := Trail.RIGHT
	var t := Trail.new(b)
	t.start()
	t.run(6)
	t.belt(12)
	t.lasers(2)
	t.checkpoint()
	t.turn(left)
	t.bridge(12, 5.0, 2)
	t.run(6)
	t.crumbles(4)
	t.run(6)
	t.checkpoint()
	t.turn(right)
	t.belt(12, true)
	t.run(5)
	t.lasers(3, 4.0)
	t.turn(right)
	t.bridge(14, 5.5, 2)
	t.run(6)
	t.patrol()
	t.mover(8)
	t.run(6)
	t.checkpoint()
	t.turn(left)
	t.belt(10)
	t.slalom(2)
	t.run(4)
	t.finish()
