extends LevelDef
## Beams, a moving platform, a sentry and a dizzy trap, all in a crosswind.


func _init() -> void:
	id = &"eye_of_storm"
	title = "Eye of the Storm"
	hint = "Wind, beams, a ride and a sentry. Keep your head."
	biome = preload("res://resources/biomes/storm.tres")
	wind = Vector3(3.0, 0.0, 0.0)
	gold_time = 34.0
	silver_time = 54.0


func build(b: LevelBuilder) -> void:
	b.start(Vector3(0, 0, 0))
	b.floor(0, -8, 8, 20)
	b.laser(Vector3(-4, 0, -7), Vector3(4, 0, -7), 1.2, 1.8)
	b.gem(Vector3(0, 0, -10))
	b.laser(Vector3(-4, 0, -12.5), Vector3(4, 0, -12.5), 1.2, 1.8, 1.5)
	b.checkpoint(Vector3(0, 0, -15.5))
	b.mover(Vector3(0, 0, -20.5), Vector2(5, 5), Vector3(0, 0, -10))
	b.gem(Vector3(0, 0, -25.5))
	b.floor(0, -38.5, 8, 11)
	b.checkpoint(Vector3(0, 0, -35))
	b.power_up(PowerUps.Kind.SHIELD, Vector3(-3, 0, -36))
	b.trap(PowerUps.Kind.DIZZY, Vector3(2.5, 0, -38))
	b.sentry(Vector3(0, 0, -42), 10.0)
	b.floor(0, -52, 3.5, 16)
	b.gem(Vector3(0, 0, -49))
	b.gem(Vector3(0, 0, -56))
	b.floor(0, -66, 8, 12)
	b.finish_at(Vector3(0, 0, -68))
