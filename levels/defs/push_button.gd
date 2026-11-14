extends LevelDef
## Floor buttons and hard-light bridges: one for good, two on a timer.


func _init() -> void:
	id = &"push_button"
	title = "Hard Light"
	hint = "Buttons make bridges. Some do not stay."
	biome = preload("res://resources/biomes/night.tres")
	gold_time = 25.0
	silver_time = 40.0


func build(b: LevelBuilder) -> void:
	b.start(Vector3(0, 0, 0))
	b.floor(0, -4, 8, 12)
	b.tip(Vector3(0, 0, -3), "Roll over the button. It builds the bridge.")
	var first := b.bridge(0, -14, 4, 8)
	b.button(Vector3(0, 0, -7), [first])
	b.gem(Vector3(0, 0, -14))

	b.floor(0, -23, 8, 10)
	b.checkpoint(Vector3(0, 0, -20.5))
	b.tip(Vector3(0, 0, -22), "A ringed button springs back up. Be quick.")
	var second := b.bridge(0, -35, 4, 14)
	b.button(Vector3(0, 0, -25.5), [second], 5.0)
	b.gem_line(Vector3(0, 0, -31), Vector3(0, 0, -39), 3)

	b.floor(0, -47, 8, 10)
	b.checkpoint(Vector3(0, 0, -44.5))
	# The last button is off to one side, so the clock starts further away.
	b.floor(8, -47, 8, 6)
	var third := b.bridge(0, -57, 4, 10)
	b.button(Vector3(10, 0, -47), [third], 7.0)
	b.gem(Vector3(7, 0, -47))
	b.gem(Vector3(0, 0, -57))
	b.floor(0, -67, 8, 10)
	b.finish_at(Vector3(0, 0, -68))
