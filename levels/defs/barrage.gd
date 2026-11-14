extends LevelDef
## Cannon hops between islands held by sentries and a patrol.


func _init() -> void:
	id = &"barrage"
	title = "Barrage"
	hint = "Three islands, and something shooting on each."
	biome = preload("res://resources/biomes/storm.tres")
	gold_time = 32.0
	silver_time = 51.0


func build(b: LevelBuilder) -> void:
	b.start(Vector3(0, 0, 0))
	b.floor(0, -3, 8, 10)
	b.cannon(Vector3(0, 0, -5), Vector3(0, 0, -30), 2.2)

	b.floor(0, -40, 12, 26)
	b.checkpoint(Vector3(0, 0, -33))
	b.power_up(PowerUps.Kind.SHIELD, Vector3(0, 0, -37))
	# The secret diamond: the left sentry on the second island is sitting on it.
	var keeper := b.sentry(Vector3(-4.5, 0, -44), 11.0)
	keeper.reveals = [b.secret(Vector3(-4.5, 0, -44), true)]
	b.sentry(Vector3(4.5, 0, -44), 11.0)
	b.gem(Vector3(-4.5, 0, -40))
	b.gem(Vector3(4.5, 0, -40))
	b.gem(Vector3(0, 0, -46))
	b.cannon(Vector3(0, 0, -50), Vector3(0, 5, -76), 2.2)

	b.floor(0, -84, 12, 24, 5)
	b.checkpoint(Vector3(0, 5, -79))
	b.patroller(Vector3(-5, 5, -84), Vector3(10, 0, 0), 3.6)
	b.sentry(Vector3(0, 5, -90), 10.0, 1.8)
	b.gem(Vector3(-4, 5, -88))
	b.gem(Vector3(4, 5, -88))
	b.finish_at(Vector3(0, 5, -94))
