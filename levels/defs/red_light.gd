extends LevelDef
## Timed laser beams across a corridor, then three in a rolling wave.


func _init() -> void:
	id = &"red_light"
	title = "Red Light"
	hint = "The beams blink. Cross on the dark."
	biome = preload("res://resources/biomes/foundry.tres")
	gold_time = 17.0
	silver_time = 27.0


func build(b: LevelBuilder) -> void:
	b.start(Vector3(0, 0, 0))
	b.floor(0, -24, 6, 52)
	b.tip(Vector3(0, 0, -4), "A beam flickers just before it lights. Cross while it is dark.")
	b.laser(Vector3(-3, 0, -10), Vector3(3, 0, -10), 1.5, 1.5)
	b.gem(Vector3(0, 0, -13))
	b.laser(Vector3(-3, 0, -16), Vector3(3, 0, -16), 1.5, 1.5, 0.75)
	b.gem(Vector3(0, 0, -19))
	b.laser(Vector3(-3, 0, -22), Vector3(3, 0, -22), 1.2, 1.4)
	b.checkpoint(Vector3(0, 0, -27))
	b.gem(Vector3(0, 0, -30))
	# A wave: each beam lights half a second after the one before it.
	b.laser(Vector3(-3, 0, -34), Vector3(3, 0, -34), 1.0, 2.0, 1.0)
	b.gem(Vector3(0, 0, -35.5))
	b.laser(Vector3(-3, 0, -37), Vector3(3, 0, -37), 1.0, 2.0, 0.5)
	b.gem(Vector3(0, 0, -38.5))
	b.laser(Vector3(-3, 0, -40), Vector3(3, 0, -40), 1.0, 2.0, 0.0)
	b.finish_at(Vector3(0, 0, -47))
