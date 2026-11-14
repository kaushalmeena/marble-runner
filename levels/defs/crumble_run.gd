extends LevelDef
## Floors that do not stay: a winding path of crumbling tiles, a hop across
## separated ones, laser bars to jump, then a crumbling staircase.


func _init() -> void:
	id = &"crumble_run"
	title = "Crumble Run"
	hint = "Sandy tiles fall. Do not stop to think."
	biome = preload("res://resources/biomes/dusk.tres")
	gold_time = 34.0
	silver_time = 55.0


func build(b: LevelBuilder) -> void:
	b.start(Vector3(0, 0, 0))
	b.tip(Vector3(0, 0, 0), "Sandy tiles drop a moment after you touch them.")
	b.floor(0, -1, 6, 6)
	var path: Array[Vector2] = [
		Vector2(0, -5.5), Vector2(0, -8.5), Vector2(0, -11.5), Vector2(3, -11.5),
		Vector2(3, -14.5), Vector2(3, -17.5), Vector2(0, -17.5), Vector2(-3, -17.5),
		Vector2(-3, -20.5), Vector2(-3, -23.5), Vector2(0, -23.5)]
	for tile in path:
		b.crumble(tile.x, tile.y)
	b.gem(Vector3(3, 0, -14.5))
	b.gem(Vector3(-3, 0, -20.5))

	b.floor(0, -28, 6, 6)
	b.checkpoint(Vector3(0, 0, -27))
	b.power_up(PowerUps.Kind.STOPWATCH, Vector3(0, 0, -29.5))
	for tile: Vector2 in [Vector2(0, -33.5), Vector2(0, -38), Vector2(2.5, -42.5), Vector2(2.5, -45.5)]:
		b.crumble(tile.x, tile.y)
	b.gem(Vector3(0, 0, -38))
	b.gem(Vector3(2.5, 0, -42.5))

	b.floor(0, -54, 6, 14)
	b.checkpoint(Vector3(0, 0, -48.5))
	b.tip(Vector3(0, 0, -48.5), "Red means back to the last ring. Jump it.")
	b.hazard(Vector3(0, 0.3, -52), Vector3(6, 0.6, 0.5))
	b.gem(Vector3(0, 0, -54.5))

	for step in 6:
		b.crumble(0, -62.5 - step * 3.0, 0.6 * (step + 1))
	b.gem(Vector3(0, 1.8, -68.5))
	b.floor(0, -83, 8, 8, 3.6, LevelBuilder.Surface.FLOOR, 0.5)
	b.finish_at(Vector3(0, 3.6, -84))
