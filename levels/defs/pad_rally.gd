extends LevelDef
## Three fast straights joined by portals: boost pads, guards crossing the
## lane, bumpers, and a ramp jump to finish.


func _init() -> void:
	id = &"pad_rally"
	title = "Pad Rally"
	hint = "Fast is easy. Fast and tidy is not."
	biome = preload("res://resources/biomes/tundra.tres")
	gold_time = 24.0
	silver_time = 40.0


func build(b: LevelBuilder) -> void:
	var thin := 0.5
	var floor_kind := LevelBuilder.Surface.FLOOR
	b.start(Vector3(0, 0, 0))
	# The secret diamond: under the lip of the first lane, on the right, well down it.
	b.secret_nook(Vector3(3, 0, -36), Vector3.RIGHT)
	b.floor(0, -22, 6, 48)
	b.power_up(PowerUps.Kind.SHIELD, Vector3(0, 0, -2.5))
	b.tip(Vector3(0, 0, -1), "Shield up before the pad if you want a clean run.")
	b.boost_pad(Vector3(0, 0, -6), 0, 18)
	b.patroller(Vector3(-2, 0, -18), Vector3(4, 0, 0), 2.5)
	b.patroller(Vector3(2, 0, -30), Vector3(-4, 0, 0), 2.5)
	b.gem(Vector3(-2, 0, -12))
	b.gem(Vector3(2, 0, -24))
	b.gem(Vector3(-2, 0, -36))
	b.portal_pair(Vector3(0, 0, -44), 180, Vector3(20, 4, 0), 0)

	b.floor(20, -22, 6, 48, 4, floor_kind, thin)
	b.checkpoint(Vector3(20, 4, -3))
	b.boost_pad(Vector3(20, 4, -7), 0, 18)
	b.bumper(Vector3(18.4, 4, -20))
	b.bumper(Vector3(21.6, 4, -28))
	b.gem(Vector3(21.5, 4, -16))
	b.gem(Vector3(18.5, 4, -24))
	b.gem(Vector3(20, 4, -36))
	b.portal_pair(Vector3(20, 4, -44), 180, Vector3(40, 8, 0), 0)

	b.floor(40, -14, 6, 32, 8, floor_kind, thin)
	b.checkpoint(Vector3(40, 8, -3))
	b.boost_pad(Vector3(40, 8, -8), 0, 22)
	b.patroller(Vector3(38, 8, -18), Vector3(4, 0, 0), 2.0)
	b.curved_ramp(Vector3(40, 8, -30), Vector3(40, 9.6, -36), 6)
	b.floor(40, -56, 10, 22, 8, floor_kind, thin)
	b.gem(Vector3(40, 8, -51))
	b.gem(Vector3(40, 8, -57))
	b.finish_at(Vector3(40, 8, -63))
