extends LevelDef
## A steady wind from the left over a path that keeps getting narrower.


func _init() -> void:
	id = &"crosswind"
	title = "Crosswind"
	hint = "The wind never stops. Lean into it."
	biome = preload("res://resources/biomes/storm.tres")
	wind = Vector3(3.0, 0.0, 0.0)
	gold_time = 20.0
	silver_time = 32.0


func build(b: LevelBuilder) -> void:
	b.start(Vector3(0, 0, 0))
	b.floor(0, -10, 12, 24)
	b.tip(Vector3(0, 0, -3), "The wind pushes you right. Steer a little left the whole way.")
	b.gem_line(Vector3(-3, 0, -8), Vector3(-3, 0, -18), 3)
	b.floor(0, -32, 6, 20)
	b.checkpoint(Vector3(0, 0, -24))
	b.gem(Vector3(-2, 0, -30))
	b.gem(Vector3(-2, 0, -38))
	b.floor(0, -52, 3.5, 20)
	b.checkpoint(Vector3(0, 0, -43.5))
	b.gem(Vector3(0, 0, -50))
	b.gem(Vector3(0, 0, -57))
	b.floor(0, -68, 10, 12)
	b.finish_at(Vector3(0, 0, -69))
