extends LevelDef
## Tar patches, the grip power-up, and a guard who is faster than you in the tar.


func _init() -> void:
	id = &"tar_pit"
	title = "Tar Pit"
	hint = "Tar slows you to a crawl. Grip does not care."
	biome = preload("res://resources/biomes/canyon.tres")
	gold_time = 21.0
	silver_time = 34.0


func build(b: LevelBuilder) -> void:
	b.start(Vector3(0, 0, 0))
	b.floor(0, -30, 10, 64)
	b.tip(Vector3(0, 0, -3), "The dark patches are tar. You crawl through it.")
	b.mud(0, -10, 10, 6)
	b.gem(Vector3(0, 0, -10))
	b.power_up(PowerUps.Kind.GRIP, Vector3(0, 0, -17))
	b.mud(0, -26, 10, 10)
	# The secret diamond: the guard in the tar is carrying it. Pop the guard.
	var keeper := b.patroller(Vector3(-4, 0, -26), Vector3(8, 0, 0), 4.0)
	keeper.reveals = [b.secret(Vector3(0, 0, -26), true)]
	b.gem(Vector3(-3, 0, -23))
	b.gem(Vector3(3, 0, -29))
	b.checkpoint(Vector3(0, 0, -34))
	# A slalom: clean lanes on alternate sides, with the gems out in the tar.
	b.mud(-2.5, -42, 5, 8)
	b.mud(2.5, -52, 5, 8)
	b.gem(Vector3(-2.5, 0, -42))
	b.gem(Vector3(2.5, 0, -52))
	b.finish_at(Vector3(0, 0, -60))
