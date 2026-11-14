extends LevelDef
## Beams that keep getting thinner, ice with and without kerbs, and bumpers to knock you off both.


func _init() -> void:
	id = &"thin_line"
	title = "Thin Line"
	hint = "Narrow, slippery, and a long way to the next checkpoint."
	biome = preload("res://resources/biomes/tundra.tres")
	gold_time = 38.0
	silver_time = 59.0


func build(b: LevelBuilder) -> void:
	var left := Trail.LEFT
	var right := Trail.RIGHT
	var t := Trail.new(b)
	t.start()
	t.beam(10, 1)
	t.run(4)
	t.ice(12, 2)
	t.run(5)
	t.secret_below(Trail.LEFT)
	t.checkpoint()
	t.turn(left)
	t.beam(14, 2, 1.6)
	t.run(4)
	t.bumpers(3)
	t.turn(right)
	t.ice(10, 1, false, 4.0)
	t.run(5)
	t.checkpoint()
	t.gap(3)
	t.run(4)
	t.beam(12, 1, 1.5)
	t.run(4)
	t.step(0.8)
	t.run(4)
	t.beam(10, 1, 1.4)
	t.run(5)
	t.turn(right)
	t.ice(12, 2)
	t.run(4)
	t.crumbles(3)
	t.run(4)
	t.finish()
