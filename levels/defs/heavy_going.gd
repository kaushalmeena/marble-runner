extends LevelDef
## A long heavy-gravity climb: low ledges, short gaps, tar, pads and a fan.


func _init() -> void:
	id = &"heavy_going"
	title = "Heavy Going"
	hint = "Heavy gravity, and nothing here is flat for long."
	biome = preload("res://resources/biomes/foundry.tres")
	gravity_scale = 1.4
	gold_time = 34.0
	silver_time = 51.0


func build(b: LevelBuilder) -> void:
	var left := Trail.LEFT
	var right := Trail.RIGHT
	var t := Trail.new(b)
	t.gravity_scale = 1.4
	t.start()
	t.run(8, 1)
	t.step(0.6)
	t.run(6)
	t.step(0.6)
	t.run(6, 1)
	t.gap(1.8)
	t.run(6)
	t.checkpoint()
	t.turn(left)
	t.mud(8)
	t.run(5)
	t.bounce(2.5)
	t.run(8, 1)
	t.beam(10, 1, 2.4)
	t.run(4)
	t.turn(right)
	t.fan(4)
	t.run(8)
	t.checkpoint()
	t.crumbles(3)
	t.run(5)
	t.slalom(2)
	t.step(0.6)
	t.run(6)
	t.gap(1.8)
	t.run(6)
	t.bounce(3)
	t.run(8, 1)
	t.finish()
