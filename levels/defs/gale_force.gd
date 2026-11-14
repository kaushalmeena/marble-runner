extends LevelDef
## Gaps in a crosswind, a double jump for the wide one, and a platform ride through the gale.


func _init() -> void:
	id = &"gale_force"
	title = "Gale Force"
	hint = "Jump early. The wind carries you sideways."
	biome = preload("res://resources/biomes/storm.tres")
	wind = Vector3(-3.0, 0.0, 0.0)
	gold_time = 30.0
	silver_time = 48.0


func build(b: LevelBuilder) -> void:
	b.start(Vector3(0, 0, 0))
	b.floor(0, -4, 8, 12)
	b.tip(Vector3(0, 0, -3), "The wind blows left. Aim your jumps a little right.")
	b.floor(0, -17, 6, 8)
	b.gem(Vector3(0, 0, -17))
	b.floor(0, -28, 6, 8)
	b.checkpoint(Vector3(0, 0, -26))
	b.power_up(PowerUps.Kind.DOUBLE_JUMP, Vector3(0, 0, -29))
	b.floor(0, -41, 6, 8)
	b.gem(Vector3(0, 0, -41))
	b.checkpoint(Vector3(0, 0, -43))
	b.mover(Vector3(0, 0, -47.5), Vector2(5, 5), Vector3(0, 0, -8))
	b.gem(Vector3(0, 0, -51.5))
	b.floor(0, -63, 8, 10)
	b.finish_at(Vector3(0, 0, -64))
