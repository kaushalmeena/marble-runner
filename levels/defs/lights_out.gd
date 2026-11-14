extends LevelDef
## The first night level: a winding path, glowing gems, and a flare.


func _init() -> void:
	id = &"lights_out"
	title = "Lights Out"
	hint = "Night. Your marble is the only lamp."
	biome = preload("res://resources/biomes/night.tres")
	dark = true
	gold_time = 21.0
	silver_time = 34.0


func build(b: LevelBuilder) -> void:
	b.start(Vector3(0, 0, 0))
	# The secret diamond: a ledge off the dead end of the first corner, out in the dark.
	b.secret_ledge(Vector3(-7.5, -2, -18))
	b.floor(0, -6, 8, 16)
	b.tip(Vector3(0, 0, -3), "It is night. Your marble lights the way, and gems glow.")
	b.gem_line(Vector3(0, 0, -5), Vector3(0, 0, -12), 3)
	b.floor(6, -18, 20, 8)
	b.gem(Vector3(6, 0, -18))
	b.power_up(PowerUps.Kind.FLARE, Vector3(13, 0, -18))
	b.floor(14, -30, 8, 16)
	b.gem(Vector3(14, 0, -28))
	b.gem(Vector3(14, 0, -35))
	b.tip(Vector3(14, 0, -33), "There is a gap ahead. Jump it.")
	b.floor(14, -45, 8, 8)
	b.checkpoint(Vector3(14, 0, -43))
	b.gem(Vector3(14, 0, -46))
	b.floor(4, -45, 12, 8)
	b.gem(Vector3(5, 0, -45))
	b.finish_at(Vector3(0, 0, -45))
