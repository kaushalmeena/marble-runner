extends LevelDef
## Introduces keys and gates: a hub with a key down one branch, gems up
## another, and a second key under a sweeping bar.


func _init() -> void:
	id = &"lock_and_key"
	title = "Lock and Key"
	hint = "The way on is shut. The key is not far."
	biome = preload("res://resources/biomes/desert.tres")
	gold_time = 40.0
	silver_time = 62.0


func build(b: LevelBuilder) -> void:
	var thin := 0.5
	b.start(Vector3(0, 0, 0))
	b.tip(Vector3(0, 0, 0), "Gates open for a key. One key, one gate.")
	b.floor(0, -8, 10, 20)

	# East: the key, on an island two guards circle.
	b.floor(10, -8, 10, 4)
	b.gem(Vector3(9, 0, -8))
	b.gem(Vector3(13, 0, -8))
	b.floor(19.5, -8, 7, 7)
	b.key(Vector3(19.5, 0, -8))
	b.patroller(Vector3(17, 0, -10.5), Vector3(5, 0, 0), 3.5)
	b.patroller(Vector3(22, 0, -5.5), Vector3(-5, 0, 0), 3.5)

	# West: a spring up to a ledge with two gems.
	b.floor(-9, -8, 8, 6)
	b.bounce_pad(Vector3(-10, 0, -9.6), 15)
	b.floor(-10, -15, 6, 7, 3, LevelBuilder.Surface.FLOOR, thin)
	b.gem(Vector3(-10, 3, -14))
	b.gem(Vector3(-10, 3, -16.5))

	b.gate(Vector3(0, 0, -19), 4)
	b.floor(0, -24, 4, 12)
	b.gem(Vector3(0, 0, -25))
	b.floor(0, -36, 12, 12)
	b.checkpoint(Vector3(0, 0, -31.5))
	b.spinner(Vector3(0, 0, -36), 9, 1.4)
	b.key(Vector3(-3, 0, -37))
	b.gem(Vector3(4.5, 0, -32))
	b.gem(Vector3(-4.5, 0, -32))
	b.gem(Vector3(4.5, 0, -40.5))

	b.floor(0, -44, 4, 4)
	b.gate(Vector3(0, 0, -43), 4)
	b.floor(0, -51, 8, 10)
	b.finish_at(Vector3(0, 0, -52))
