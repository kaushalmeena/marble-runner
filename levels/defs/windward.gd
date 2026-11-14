extends LevelDef
## One steady wind over a course that turns through it: across it, into it, and across it on ice.


func _init() -> void:
	id = &"windward"
	title = "Windward"
	hint = "The wind is the same all the way. The path is not."
	biome = preload("res://resources/biomes/storm.tres")
	wind = Vector3(2.5, 0.0, 0.0)
	gold_time = 43.0
	silver_time = 66.0


func build(b: LevelBuilder) -> void:
	var left := Trail.LEFT
	var right := Trail.RIGHT
	var t := Trail.new(b)
	t.start()
	t.run(8, 1)
	t.beam(10, 1, 3.0)
	t.run(5)
	t.gap(3)
	t.run(6)
	t.checkpoint()
	t.turn(left)
	t.run(10, 2)
	t.slalom(2)
	t.turn(right)
	t.ice(10, 1)
	t.run(5)
	t.power(PowerUps.Kind.GRIP)
	t.beam(14, 2, 2.0)
	t.run(5)
	t.checkpoint()
	t.lasers(2)
	t.mover(8)
	t.run(6)
	t.turn(right)
	t.crumbles(3)
	t.run(6)
	t.step(0.8)
	t.run(6, 1)
	t.finish()
