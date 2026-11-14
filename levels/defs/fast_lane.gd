extends LevelDef
## Speed: boost pads into launch ramps, then a gap that needs the boost
## power-up and a jump together.


func _init() -> void:
	id = &"fast_lane"
	title = "Fast Lane"
	hint = "Hit the ramps straight and let go."
	biome = preload("res://resources/biomes/desert.tres")
	gold_time = 20.0
	silver_time = 36.0


func build(b: LevelBuilder) -> void:
	b.start(Vector3(0, 0, 0))
	b.tip(Vector3(0, 0, 0), "Green pads fling you forward. Line up with the ramp first.")
	b.floor(0, -5, 6, 14)
	b.boost_pad(Vector3(0, 0, -5), 0, 22)
	b.ramp(Vector3(0, 0, -12), Vector3(0, 1.6, -16), 6)

	b.floor(0, -38, 8, 26)
	b.checkpoint(Vector3(0, 0, -36))
	b.gem_line(Vector3(0, 0, -40), Vector3(0, 0, -48), 3)

	b.floor(-12, -47, 16, 8)
	b.boost_pad(Vector3(-9, 0, -47), 90, 22)
	b.ramp(Vector3(-20, 0, -47), Vector3(-24, 1.6, -47), 6)
	b.floor(-46, -47, 26, 8)
	b.checkpoint(Vector3(-44, 0, -47))
	b.gem_line(Vector3(-48, 0, -47), Vector3(-56, 0, -47), 3)

	b.floor(-55, -60, 8, 18)
	b.power_up(PowerUps.Kind.BOOST, Vector3(-55, 0, -54))
	b.tip(Vector3(-55, 0, -53), "Too far to jump. Spend the BOOST, then jump at the edge.")
	b.floor(-55, -86, 10, 16)
	b.gem(Vector3(-55, 0, -82))
	b.finish_at(Vector3(-55, 0, -88))
