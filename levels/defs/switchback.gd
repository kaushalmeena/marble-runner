extends LevelDef
## A zigzag climb of ramps and hairpins, a ledge by bounce pad, then a glide back down.


func _init() -> void:
	id = &"switchback"
	title = "Switchback"
	hint = "Up the mountain the slow way, down it the fast way."
	biome = preload("res://resources/biomes/canyon.tres")
	gold_time = 35.0
	silver_time = 53.0


func build(b: LevelBuilder) -> void:
	var left := Trail.LEFT
	var right := Trail.RIGHT
	var t := Trail.new(b)
	t.start()
	t.run(6, 1)
	t.ramp(12, 3)
	t.turn(left)
	t.turn(left)
	t.ramp(12, 3)
	t.turn(right)
	t.turn(right)
	t.ramp(12, 3)
	t.run(6)
	t.secret_below(Trail.RIGHT)
	t.checkpoint()
	t.beam(10, 1)
	t.run(4)
	t.step(0.8)
	t.run(7)
	t.bounce(3)
	t.run(9, 1)
	t.checkpoint()
	t.tip("A long way down. Take the plane, run, and jump.")
	t.glide(18, 6)
	t.run(10, 1)
	t.slalom(2)
	t.crumbles(4)
	t.run(6)
	t.gap(3.5)
	t.run(5)
	t.finish()
