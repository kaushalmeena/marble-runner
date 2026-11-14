extends LevelDef
## Patrolling rivals and laser beams in the dark, with a flare half way.


func _init() -> void:
	id = &"night_watch"
	title = "Night Watch"
	hint = "Guards and beams, and no light but yours."
	biome = preload("res://resources/biomes/night.tres")
	dark = true
	gold_time = 18.0
	silver_time = 29.0


func build(b: LevelBuilder) -> void:
	b.start(Vector3(0, 0, 0))
	b.floor(0, -24, 8, 52)
	b.patroller(Vector3(-3, 0, -10), Vector3(6, 0, 0), 4.0)
	b.gem(Vector3(0, 0, -13))
	b.laser(Vector3(-4, 0, -18), Vector3(4, 0, -18), 1.4, 1.6)
	b.power_up(PowerUps.Kind.FLARE, Vector3(0, 0, -22))
	b.patroller(Vector3(3, 0, -26), Vector3(-6, 0, 0), 3.4)
	b.gem(Vector3(-2, 0, -29))
	b.checkpoint(Vector3(0, 0, -31))
	b.laser(Vector3(-4, 0, -36), Vector3(4, 0, -36), 1.2, 1.8)
	b.gem(Vector3(0, 0, -38))
	b.laser(Vector3(-4, 0, -40), Vector3(4, 0, -40), 1.2, 1.8, 1.5)
	b.patroller(Vector3(-3, 0, -44), Vector3(6, 0, 0), 3.0)
	b.gem(Vector3(2, 0, -46))
	b.finish_at(Vector3(0, 0, -48))
