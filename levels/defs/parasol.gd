extends LevelDef
## Fans up and glides down, three times over, each leap longer than the last.


func _init() -> void:
	id = &"parasol"
	title = "Thermals"
	hint = "Up on the wind, down on the wing."
	biome = preload("res://resources/biomes/dusk.tres")
	gold_time = 32.0
	silver_time = 49.0


func build(b: LevelBuilder) -> void:
	var left := Trail.LEFT
	var right := Trail.RIGHT
	var t := Trail.new(b)
	t.start()
	t.run(6)
	t.fan(4)
	t.run(9, 1)
	t.secret_side(Trail.LEFT)
	t.checkpoint()
	t.glide(18, 5)
	t.run(10, 1)
	t.turn(right)
	t.fan(5)
	t.run(9)
	t.glide(21, 6)
	t.run(10, 2)
	t.checkpoint()
	t.turn(left)
	t.run(5)
	t.bounce(3)
	t.run(8)
	t.beam(8, 1)
	t.run(8)
	t.glide(17, 3)
	t.run(10)
	t.crumbles(3)
	t.run(5)
	t.finish()
