extends LevelDef
## Everything so far, one after another, with a checkpoint between each.


func _init() -> void:
	id = &"gauntlet"
	title = "The Gauntlet"
	hint = "You have seen all of this before. Not in a row."
	biome = preload("res://resources/biomes/dusk.tres")
	gold_time = 70.0
	silver_time = 105.0


func build(b: LevelBuilder) -> void:
	var ice := LevelBuilder.Surface.ICE
	var floor_kind := LevelBuilder.Surface.FLOOR
	b.start(Vector3(0, 0, 0))
	b.floor(0, -3, 6, 10)
	b.boost_pad(Vector3(0, 0, -3.5), 0, 22)
	b.curved_ramp(Vector3(0, 0, -8), Vector3(0, 1.6, -14), 6)

	b.floor(0, -34, 8, 26)
	b.checkpoint(Vector3(0, 0, -31))
	b.spinner(Vector3(0, 0, -39), 7.4, 1.6)
	b.gem(Vector3(-2.5, 0, -39))
	b.gem(Vector3(2.5, 0, -39))

	b.mover(Vector3(0, 0, -49.2), Vector2(4, 4), Vector3(0, 0, -10), 8.0)
	b.gem(Vector3(0, 0, -54))
	b.floor(0, -69.4, 6, 16, 0, ice)
	b.bumper(Vector3(-1.5, 0, -66))
	b.bumper(Vector3(1.5, 0, -72))
	b.gem(Vector3(1.5, 0, -66))
	b.gem(Vector3(-1.5, 0, -72))

	b.floor(0, -81.4, 8, 8)
	b.checkpoint(Vector3(0, 0, -80))
	b.power_up(PowerUps.Kind.SUPER_JUMP, Vector3(0, 0, -82.5))
	b.floor(0, -90.4, 8, 10, 3.2, floor_kind, 4.2)
	b.gem(Vector3(0, 3.2, -90))

	b.fan(Vector3(0, 0, -98.6), 16)
	b.gem(Vector3(0, 7, -98.6))
	b.floor(0, -105.6, 8, 8, 7, floor_kind, 0.5)
	b.checkpoint(Vector3(0, 7, -104))
	for step in 4:
		b.crumble(0, -111.1 - step * 3.0, 7)
	b.hazard(Vector3(0, 7.3, -115.6), Vector3(3, 0.6, 0.4))
	b.gem(Vector3(0, 7, -112.6))
	b.floor(0, -126.6, 10, 10, 7, floor_kind, 0.5)
	b.finish_at(Vector3(0, 7, -128))
