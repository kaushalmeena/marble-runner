extends LevelDef
## Moving platforms, a portal to a tower with the key on it, a lift behind a
## gate, and a sweeping bar on the last landing.


func _init() -> void:
	id = &"clockwork_2"
	title = "Clockwork"
	hint = "Everything here moves on a schedule."
	biome = preload("res://resources/biomes/tundra.tres")
	gold_time = 75.0
	silver_time = 118.0


func build(b: LevelBuilder) -> void:
	var thin := 0.5
	var floor_kind := LevelBuilder.Surface.FLOOR
	var pad := Vector2(4, 4)
	b.start(Vector3(0, 0, 0))
	b.floor(0, -2, 6, 8)
	b.mover(Vector3(0, 0, -8.2), pad, Vector3(0, 0, -9), 8.0)
	b.gem(Vector3(0, 0, -12.7))

	b.floor(0, -23.4, 10, 8)
	b.checkpoint(Vector3(0, 0, -21))
	b.gem(Vector3(-3, 0, -25))
	b.tip(Vector3(0, 0, -22), "The key is up on the tower. The ring goes both ways.")
	b.portal_pair(Vector3(3.6, 0, -23.4), 90, Vector3(14, 6, -21.5), 0)
	b.floor(14, -24.4, 6, 8, 6, floor_kind, thin)
	b.key(Vector3(14, 6, -27))
	b.gem(Vector3(16, 6, -27))
	b.patroller(Vector3(12, 6, -24.8), Vector3(4, 0, 0), 3.0)

	b.gate(Vector3(0, 0, -28), 4)
	b.floor(0, -29.9, 4, 5)
	b.mover(Vector3(0, 0, -34.6), pad, Vector3(0, 5, 0), 8.0)
	b.floor(0, -41.8, 8, 10, 5, floor_kind, thin)
	b.checkpoint(Vector3(0, 5, -38.5))
	b.spinner(Vector3(0, 5, -42.5), 7, 1.5)
	b.gem(Vector3(-3, 5, -45.5))
	b.gem(Vector3(3, 5, -45.5))
	b.mover(Vector3(6.2, 5, -42), pad, Vector3(9, 0, 0), 8.0, 0.5)
	b.gem(Vector3(10.7, 5, -42))
	b.floor(21.4, -42, 8, 8, 5, floor_kind, thin)
	# The finish used to stand here. Now it is a checkpoint, and the level
	# carries on: the second half is laid out as a trail.
	b.checkpoint(Vector3(22.4, 5, -42))
	var left := Trail.LEFT
	var t := Trail.new(b, Vector3(25.4, 5, -42), 3)
	t.mover(8)
	t.run(6)
	t.crumbles(3)
	t.run(5)
	t.turn(left)
	t.bridge(12, 5.0, 2)
	t.run(6)
	t.mover(10)
	t.run(6)
	t.lasers(2)
	t.run(4)
	t.finish()
