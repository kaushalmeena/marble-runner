extends LevelDef
## Introduces water: a shallow pool to learn in, then a deeper one with a key
## on the bottom and guards swimming lengths.


func _init() -> void:
	id = &"deep_end"
	title = "Deep End"
	hint = "You sink slowly. Space swims up."
	biome = preload("res://resources/biomes/reef.tres")
	gold_time = 30.0
	silver_time = 50.0


func build(b: LevelBuilder) -> void:
	var floor_kind := LevelBuilder.Surface.FLOOR
	var wall := LevelBuilder.Surface.WALL
	b.start(Vector3(0, 0, 0))
	b.tip(Vector3(0, 0, 0), "Roll in. You sink slowly, and SPACE swims you up.")
	b.floor(0, -2, 10, 8, 0, floor_kind, 5.5)

	b.floor(0, -14, 10, 16, -5)
	b.box(Vector3(-5.25, -2.25, -14), Vector3(0.5, 6.5, 16), wall)
	b.box(Vector3(5.25, -2.25, -14), Vector3(0.5, 6.5, 16), wall)
	b.water(Vector3(0, -2.5, -14), Vector3(10, 5, 16))
	b.ramp(Vector3(0, -5, -16), Vector3(0, 0, -22), 10)
	b.gem(Vector3(-3, -5, -9))
	b.gem(Vector3(3, -5, -12))
	b.gem(Vector3(0, -2.5, -14))
	b.patroller(Vector3(-3.5, -4.5, -15), Vector3(7, 0, 0), 4.5)

	b.floor(0, -27, 10, 10, 0, floor_kind, 7.5)
	b.checkpoint(Vector3(0, 0, -25))
	b.tip(Vector3(0, 0, -26), "The gate ahead wants a key. It is on the bottom.")
	b.floor(0, -41, 10, 18, -7)
	b.box(Vector3(-5.25, -3.25, -41), Vector3(0.5, 8.5, 18), wall)
	b.box(Vector3(5.25, -3.25, -41), Vector3(0.5, 8.5, 18), wall)
	b.water(Vector3(0, -3.5, -41), Vector3(10, 7, 18))
	b.ramp(Vector3(0, -7, -42), Vector3(0, 0, -50), 10)
	b.key(Vector3(-3, -7, -40))
	b.gem(Vector3(-3, -7, -35))
	b.gem(Vector3(3, -7, -38))
	b.gem(Vector3(0, -3.5, -36))
	b.patroller(Vector3(-3.5, -6.5, -37.5), Vector3(7, 0, 0), 4.0)
	b.patroller(Vector3(3.5, -6.5, -34.5), Vector3(0, 4.5, 0), 3.5)

	b.floor(0, -56, 10, 12, 0, floor_kind, 7.5)
	b.gate(Vector3(0, 0, -52), 10)
	b.finish_at(Vector3(0, 0, -58))
