extends LevelDef
## Chasers: guards that hunt the marble, but only inside their own arena.
## One to learn on, then two guarding a key.


func _init() -> void:
	id = &"hunted"
	title = "Hunted"
	hint = "Purple ones follow. Keep moving."
	biome = preload("res://resources/biomes/dusk.tres")
	gold_time = 34.0
	silver_time = 56.0


func build(b: LevelBuilder) -> void:
	b.start(Vector3(0, 0, -3.5))
	b.tip(Vector3(0, 0, -3.5), "Purple marbles hunt you, but only on their own patch.")
	b.floor(0, -12, 20, 20)
	_ring_walls(b, -12)
	b.chaser(Vector3(0, 0, -13), 9, 4.5)
	b.gem_ring(Vector3(0, 0, -12), 7, 6)
	b.bumper(Vector3(-4, 0, -9))
	b.bumper(Vector3(4, 0, -15))
	b.power_up(PowerUps.Kind.SHIELD, Vector3(8, 0, -4))

	b.floor(0, -27, 3, 10)
	b.checkpoint(Vector3(0, 0, -30))
	b.floor(0, -42, 20, 20)
	_ring_walls(b, -42)
	b.chaser(Vector3(-5, 0, -43), 8, 4.0)
	b.chaser(Vector3(5, 0, -43), 8, 5.0)
	b.key(Vector3(0, 0, -42))
	for corner: Vector2 in [Vector2(-8, -34.5), Vector2(8, -34.5), Vector2(-8, -49.5), Vector2(8, -49.5)]:
		b.gem(Vector3(corner.x, 0, corner.y))
	b.boost_pad(Vector3(-8.5, 0, -39), 0, 16)
	b.boost_pad(Vector3(8.5, 0, -45), 180, 16)
	b.power_up(PowerUps.Kind.SHIELD, Vector3(0, 0, -34))

	b.floor(0, -55, 4, 6)
	b.gate(Vector3(0, 0, -53), 4)
	b.floor(0, -63, 8, 10)
	b.finish_at(Vector3(0, 0, -64))


## Kerbs round a 20 by 20 arena centred on [param z], with a gap front and back.
func _ring_walls(b: LevelBuilder, z: float) -> void:
	for side: float in [-1.0, 1.0]:
		b.wall(Vector3(side * 9.8, 0, z - 9.8), Vector3(side * 9.8, 0, z + 9.8))
		for end: float in [-1.0, 1.0]:
			b.wall(Vector3(side * 9.8, 0, z + end * 9.8), Vector3(side * 1.9, 0, z + end * 9.8))
