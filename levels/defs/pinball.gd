extends LevelDef
## Bumpers in a walled alley, a plaza with a sweeping bar, then a narrow bridge
## the bar sweeps across.


func _init() -> void:
	id = &"pinball"
	title = "Pinball"
	hint = "Red posts hit back."
	biome = preload("res://resources/biomes/tundra.tres")
	gold_time = 32.0
	silver_time = 50.0


func build(b: LevelBuilder) -> void:
	b.start(Vector3(0, 0, 0))
	# The secret diamond: outside the spinner hall, over its right wall.
	b.secret_ledge(Vector3(11.5, -2.5, -40))
	b.floor(0, -3, 8, 10)
	b.floor(0, -20, 10, 24)
	b.wall(Vector3(-4.8, 0, -8), Vector3(-4.8, 0, -32), 1.0)
	b.wall(Vector3(4.8, 0, -8), Vector3(4.8, 0, -32), 1.0)
	for spot: Vector2 in [
			Vector2(-2, -12), Vector2(2, -12), Vector2(0, -16), Vector2(-3, -20),
			Vector2(3, -20), Vector2(0, -24), Vector2(-2, -28), Vector2(2, -28)]:
		b.bumper(Vector3(spot.x, 0, spot.y))
	for spot: Vector2 in [
			Vector2(0, -12), Vector2(-2.5, -16), Vector2(2.5, -16), Vector2(0, -20),
			Vector2(0, -28)]:
		b.gem(Vector3(spot.x, 0, spot.y))

	b.floor(0, -40, 18, 16)
	b.wall(Vector3(-8.8, 0, -32), Vector3(-8.8, 0, -48))
	b.wall(Vector3(8.8, 0, -32), Vector3(8.8, 0, -48))
	b.wall(Vector3(-8.8, 0, -32.2), Vector3(-5, 0, -32.2))
	b.wall(Vector3(5, 0, -32.2), Vector3(8.8, 0, -32.2))
	b.wall(Vector3(-8.8, 0, -47.8), Vector3(-1.7, 0, -47.8))
	b.wall(Vector3(1.7, 0, -47.8), Vector3(8.8, 0, -47.8))
	b.checkpoint(Vector3(0, 0, -34))
	b.tip(Vector3(0, 0, -34), "Jump the bar, or run round with it.")
	b.spinner(Vector3(0, 0, -40), 15, 1.3)
	b.gem_ring(Vector3(0, 0, -40), 6, 6)

	b.floor(0, -55, 3, 14)
	b.floor(4.5, -55, 2, 2)
	b.spinner(Vector3(4.5, 0, -55), 13, -1.7)
	b.gem(Vector3(0, 0, -51))
	b.gem(Vector3(0, 0, -59))
	b.floor(0, -67, 8, 10)
	b.finish_at(Vector3(0, 0, -68))
