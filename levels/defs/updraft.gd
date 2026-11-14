extends LevelDef
## Air: fan columns that lift the marble to a hover, and the feather, which
## turns a jump into a glide.


func _init() -> void:
	id = &"updraft"
	title = "Updraft"
	hint = "Roll off the edge. Trust the fan."
	biome = preload("res://resources/biomes/dusk.tres")
	gold_time = 32.0
	silver_time = 55.0


func build(b: LevelBuilder) -> void:
	var thin := 0.5
	var floor_kind := LevelBuilder.Surface.FLOOR
	b.start(Vector3(0, 0, 0))
	b.tip(Vector3(0, 0, 0), "Fans hold you up. Drift forward out of the column.")
	b.floor(0, -2, 8, 8)
	b.fan(Vector3(0, -3, -10), 14)
	b.gem(Vector3(0, 3, -10))

	b.floor(0, -17, 8, 8, 3, floor_kind, thin)
	b.checkpoint(Vector3(0, 3, -15))
	b.power_up(PowerUps.Kind.FEATHER, Vector3(0, 3, -17.5))
	b.tip(Vector3(0, 3, -16), "Take a run up, jump, then SHIFT to float across.")
	b.gem(Vector3(0, 3, -19.5))

	b.floor(0, -44, 8, 16, 3, floor_kind, thin)
	b.checkpoint(Vector3(0, 3, -39))
	b.gem(Vector3(-2, 3, -43))
	b.fan(Vector3(7, -2, -41), 16)
	b.gem(Vector3(7, 5, -41))

	b.floor(14, -41, 8, 8, 5, floor_kind, thin)
	b.checkpoint(Vector3(14, 5, -41))
	b.gem(Vector3(16, 5, -39))
	b.fan(Vector3(14, 1, -48), 16)
	b.gem(Vector3(14, 8, -48))
	b.floor(14, -55, 8, 8, 8, floor_kind, thin)
	b.finish_at(Vector3(14, 8, -56))
