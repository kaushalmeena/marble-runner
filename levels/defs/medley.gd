extends LevelDef
## Every kind of stretch once: belt, bridge, fan, glide, beams, stones, a ride, a pad, a cannon and an arena.


func _init() -> void:
	id = &"medley"
	title = "Medley"
	hint = "A little of everything, with no time to settle."
	biome = preload("res://resources/biomes/dusk.tres")
	gold_time = 76.0
	silver_time = 117.0


func build(b: LevelBuilder) -> void:
	var left := Trail.LEFT
	var right := Trail.RIGHT
	var t := Trail.new(b)
	t.start()
	t.run(6, 1)
	t.belt(10)
	t.gap(3)
	t.run(6)
	t.step(0.8)
	t.run(6)
	t.secret_switch(Trail.RIGHT)
	t.checkpoint()
	t.turn(left)
	t.bridge(12, 5.0, 2)
	t.run(6)
	t.fan(4)
	t.run(9)
	t.glide(18, 5)
	t.run(10, 1)
	t.checkpoint()
	t.turn(right)
	t.lasers(2)
	t.crumbles(3)
	t.run(6)
	t.mover(8)
	t.run(6)
	t.turn(right)
	t.slalom(2)
	t.bounce(3)
	t.run(9)
	t.cannon(26, 3)
	t.run(18, 2)
	t.secret_reveal()
	t.checkpoint()
	t.beam(10, 1, 1.6)
	t.run(5)
	t.arena(14, 6, 1)
	t.run(5)
	t.finish()
