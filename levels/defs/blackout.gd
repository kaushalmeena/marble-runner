extends LevelDef
## Night and wind together over button bridges and beams.


func _init() -> void:
	id = &"blackout"
	title = "Blackout"
	hint = "Dark, windy, and the bridges are timed."
	biome = preload("res://resources/biomes/night.tres")
	dark = true
	wind = Vector3(2.5, 0.0, 0.0)
	gold_time = 18.0
	silver_time = 29.0


func build(b: LevelBuilder) -> void:
	b.start(Vector3(0, 0, 0))
	b.floor(0, -6, 6, 16)
	var first := b.bridge(0, -19, 4, 10)
	b.button(Vector3(0, 0, -11), [first])
	b.gem(Vector3(0, 0, -19))
	b.floor(0, -30, 6, 12)
	b.checkpoint(Vector3(0, 0, -26))
	b.power_up(PowerUps.Kind.FLARE, Vector3(-1.5, 0, -28))
	b.laser(Vector3(-3, 0, -31), Vector3(3, 0, -31), 1.2, 1.8)
	var second := b.bridge(0, -43, 4, 14)
	b.button(Vector3(0, 0, -34), [second], 6.0)
	b.gem_line(Vector3(0, 0, -39), Vector3(0, 0, -47), 3)
	b.floor(0, -56, 8, 12)
	b.finish_at(Vector3(0, 0, -58))
