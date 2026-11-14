extends LevelDef
## The first long level: every basic move, strung into one winding course.


func _init() -> void:
	id = &"long_way_round"
	title = "Long Haul"
	hint = "A proper course. Pace yourself."
	biome = preload("res://resources/biomes/meadow.tres")
	gold_time = 41.0
	silver_time = 63.0


func build(b: LevelBuilder) -> void:
	var left := Trail.LEFT
	var right := Trail.RIGHT
	var t := Trail.new(b)
	t.start()
	t.secret_behind()
	t.tip("This one is long. Checkpoints hold your place.")
	t.run(10, 2)
	t.gap(3)
	t.run(8, 1)
	t.turn(left)
	t.run(10, 1)
	t.step(0.8)
	t.run(8, 1)
	t.step(0.8)
	t.run(6)
	t.checkpoint()
	t.turn(right)
	t.beam(12, 2)
	t.run(6)
	t.slalom(3)
	t.turn(right)
	t.run(6)
	t.gap(3.5)
	t.run(6, 1)
	t.gap(3.5)
	t.run(6)
	t.checkpoint()
	t.turn(left)
	t.ramp(10, 3)
	t.run(6)
	t.bumpers(3)
	t.drop(3)
	t.run(8, 2)
	t.finish()
