extends LevelDef
## Wind over ice: a sheet with a kerb to lean on, then a narrow one with nothing.


func _init() -> void:
	id = &"stormglass"
	title = "Stormglass"
	hint = "Ice underfoot and a wind to push you across it."
	biome = preload("res://resources/biomes/tundra.tres")
	wind = Vector3(2.5, 0.0, 0.0)
	gold_time = 27.0
	silver_time = 43.0


func build(b: LevelBuilder) -> void:
	var ice := LevelBuilder.Surface.ICE
	b.start(Vector3(0, 0, 0))
	b.floor(0, -5, 8, 14)
	b.tip(Vector3(0, 0, -3), "On ice the wind wins. Let it pin you to the kerb and roll along it.")
	b.floor(0, -22, 10, 20, 0, ice)
	b.wall(Vector3(5.2, 0, -12), Vector3(5.2, 0, -32))
	b.gem_line(Vector3(4, 0, -17), Vector3(4, 0, -29), 3)
	b.floor(0, -37, 8, 10)
	b.checkpoint(Vector3(0, 0, -34.5))
	b.power_up(PowerUps.Kind.GRIP, Vector3(0, 0, -38))
	b.tip(Vector3(0, 0, -36), "No kerb on the next sheet. Take the grip.")
	b.floor(0, -52, 5, 20, 0, ice)
	b.gem_line(Vector3(0, 0, -46), Vector3(0, 0, -58), 3)
	b.floor(0, -67, 8, 10)
	b.finish_at(Vector3(0, 0, -68))
