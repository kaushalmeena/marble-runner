extends LevelDef
## Three islands and the cannons that join them.


func _init() -> void:
	id = &"cannonball"
	title = "Cannonball"
	hint = "Roll into the barrel and let go."
	biome = preload("res://resources/biomes/canyon.tres")
	gold_time = 30.0
	silver_time = 48.0


func build(b: LevelBuilder) -> void:
	b.start(Vector3(0, 0, 0))
	# The secret diamond: a ledge off the right side of the second island, a jump down.
	b.secret_ledge(Vector3(22.5, 2, -78))
	b.floor(0, -3, 8, 10)
	b.tip(Vector3(0, 0, -2), "Roll into the cannon. It knows where you are going.")
	b.cannon(Vector3(0, 0, -5), Vector3(0, 0, -30), 2.2)

	b.floor(0, -38, 10, 22)
	b.checkpoint(Vector3(0, 0, -34))
	b.gem_line(Vector3(-3, 0, -38), Vector3(3, 0, -38), 3)
	b.cannon(Vector3(0, 0, -46), Vector3(14, 4, -70), 2.2)

	b.floor(14, -76, 10, 20, 4)
	b.checkpoint(Vector3(14, 4, -74))
	b.gem_line(Vector3(11, 4, -78), Vector3(17, 4, -78), 3)
	b.cannon(Vector3(14, 4, -83), Vector3(0, 0, -108), 2.0)

	b.floor(0, -114, 10, 20)
	b.gem(Vector3(0, 0, -114))
	b.finish_at(Vector3(0, 0, -120))
