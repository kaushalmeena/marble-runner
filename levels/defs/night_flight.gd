extends LevelDef
## Cannon shots and glides in the dark, with beams and a patrol between them.


func _init() -> void:
	id = &"night_flight"
	title = "Night Flight"
	hint = "Cannons and a plane, and you cannot see where you land."
	biome = preload("res://resources/biomes/night.tres")
	dark = true
	gold_time = 32.0
	silver_time = 50.0


func build(b: LevelBuilder) -> void:
	var left := Trail.LEFT
	var right := Trail.RIGHT
	var t := Trail.new(b)
	t.start()
	# Two stretches, so the gem stands well short of the cannon.
	t.run(2, 1)
	t.run(4)
	t.cannon(26, 4)
	t.run(18, 2)
	t.secret_side(Trail.RIGHT)
	t.checkpoint()
	t.lasers(2)
	t.turn(left)
	t.glide(18, 6)
	t.run(10, 1)
	t.power(PowerUps.Kind.FLARE)
	t.turn(right)
	t.cannon(28)
	t.run(18, 1)
	t.patrol()
	t.checkpoint()
	t.beam(10, 1)
	t.run(5)
	t.bounce(3)
	t.run(9)
	t.glide(16, 4)
	t.run(10, 1)
	t.lasers(3, 4.0)
	t.finish()
