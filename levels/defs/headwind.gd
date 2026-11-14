extends LevelDef
## A wind dead against the marble: boost pads to beat it, gaps it shortens, and grip to ignore it.


func _init() -> void:
	id = &"headwind"
	title = "Headwind"
	hint = "Straight into it. Jumps come up short."
	biome = preload("res://resources/biomes/storm.tres")
	wind = Vector3(0.0, 0.0, 4.0)
	gold_time = 19.0
	silver_time = 30.0


func build(b: LevelBuilder) -> void:
	b.start(Vector3(0, 0, 0))
	# The secret diamond: under the lip of the first floor, on the right.
	b.secret_nook(Vector3(4, 0, -20), Vector3.RIGHT)
	b.floor(0, -14, 8, 32)
	b.tip(Vector3(0, 0, -3), "The wind is against you. Jumps fall short in it.")
	b.boost_pad(Vector3(0, 0, -8), 0, 16)
	b.gem_line(Vector3(0, 0, -14), Vector3(0, 0, -26), 3)
	b.floor(0, -38.5, 8, 12)
	b.checkpoint(Vector3(0, 0, -35))
	b.power_up(PowerUps.Kind.GRIP, Vector3(0, 0, -39))
	b.tip(Vector3(0, 0, -37), "Grip holds you steady. The wind cannot touch you.")
	b.gem(Vector3(0, 0, -42))
	b.floor(0, -54, 8, 13)
	b.gem(Vector3(0, 0, -52))
	b.finish_at(Vector3(0, 0, -58))
