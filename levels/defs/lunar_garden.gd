extends LevelDef
## An open low-gravity arena: gems on the ground, on mesas and on a tower that
## needs a double jump, with two chasers and a long patrol across the back.


func _init() -> void:
	id = &"lunar_garden"
	title = "Lunar Garden"
	hint = "Up is cheap here. Use it to get away."
	biome = preload("res://resources/biomes/moon.tres")
	gravity_scale = 0.35
	gold_time = 45.0
	silver_time = 75.0


func build(b: LevelBuilder) -> void:
	var rock := LevelBuilder.Surface.WALL
	b.start(Vector3(0, 0, 14))
	b.tip(Vector3(0, 0, 14), "Gems are on the ground, the mesas and the tower.")
	b.floor(0, 0, 36, 36)
	b.wall(Vector3(-17.8, 0, -17.8), Vector3(17.8, 0, -17.8))
	b.wall(Vector3(-17.8, 0, 17.8), Vector3(17.8, 0, 17.8))
	b.wall(Vector3(-17.8, 0, -17.8), Vector3(-17.8, 0, 17.8))
	b.wall(Vector3(17.8, 0, -17.8), Vector3(17.8, 0, 17.8))

	b.floor(-9, -6, 6, 6, 3, rock, 3)
	b.gem(Vector3(-9, 3, -6))
	b.floor(9, -6, 6, 6, 3, rock, 3)
	b.gem(Vector3(9, 3, -6))
	b.floor(0, -9, 4, 4, 7, rock, 7)
	b.gem(Vector3(0, 7, -9))
	b.power_up(PowerUps.Kind.DOUBLE_JUMP, Vector3(0, 0, 3))
	b.power_up(PowerUps.Kind.SHIELD, Vector3(0, 0, 10))
	for corner: Vector2 in [Vector2(-15, -15), Vector2(15, -15), Vector2(-15, 15), Vector2(15, 15)]:
		b.gem(Vector3(corner.x, 0, corner.y))

	b.chaser(Vector3(-9, 0, 6), 8, 4.0)
	b.chaser(Vector3(9, 0, 6), 8, 4.0)
	b.patroller(Vector3(-14, 0, -13.5), Vector3(28, 0, 0), 7.0)
	b.finish_at(Vector3(0, 0, -15.5))
