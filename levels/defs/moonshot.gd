extends LevelDef
## A long moon course: gaps ten units wide, ledges three high, and a chaser at the end.


func _init() -> void:
	id = &"moonshot"
	title = "Moonshot"
	hint = "Low gravity. Every gap is a canyon."
	biome = preload("res://resources/biomes/moon.tres")
	gravity_scale = 0.35
	gold_time = 40.0
	silver_time = 61.0


func build(b: LevelBuilder) -> void:
	var left := Trail.LEFT
	var right := Trail.RIGHT
	var t := Trail.new(b)
	t.start()
	t.run(8, 1)
	t.gap(10)
	t.run(14, 1)
	t.step(3)
	t.run(10)
	t.checkpoint()
	t.turn(left)
	t.gap(12)
	t.run(14, 2)
	t.crumbles(4)
	t.run(8)
	t.turn(right)
	t.beam(14, 2, 2.4)
	t.run(6)
	t.step(3.5)
	t.run(10, 1)
	t.checkpoint()
	t.gap(14)
	t.run(16, 1)
	t.arena(14, 6, 1)
	t.run(8)
	t.patrol()
	t.finish()
