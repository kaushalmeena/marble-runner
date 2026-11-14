extends LevelDef
## One deep pool split in two by a wall with a gate at the bottom. A key in
## each half, guards in both, and a chaser on the floor of the second.


func _init() -> void:
	id = &"sunken_vault"
	title = "Sunken Vault"
	hint = "Two keys, both under water."
	biome = preload("res://resources/biomes/reef.tres")
	gold_time = 50.0
	silver_time = 80.0


func build(b: LevelBuilder) -> void:
	var floor_kind := LevelBuilder.Surface.FLOOR
	var wall := LevelBuilder.Surface.WALL
	b.start(Vector3(0, 0, 0))
	b.floor(0, -2, 12, 8, 0, floor_kind, 8.5)
	b.floor(0, -24, 12, 36, -8)
	b.box(Vector3(-6.25, -3.4, -24), Vector3(0.5, 10.2, 36), wall)
	b.box(Vector3(6.25, -3.4, -24), Vector3(0.5, 10.2, 36), wall)
	b.water(Vector3(0, -4, -24), Vector3(12, 8, 36))

	# The dividing wall: solid from just above the gate to above the surface.
	b.box(Vector3(0, -2.1, -18), Vector3(12, 7.0, 0.6), wall)
	b.gate(Vector3(0, -8, -18), 12)
	b.tip(Vector3(0, 0, -1), "The wall has a gate at the bottom. Find the first key.")
	b.key(Vector3(-4, -8, -14))
	b.patroller(Vector3(-4.5, -7.5, -11), Vector3(9, 0, 0), 5.0)
	b.gem(Vector3(4, -8, -9))
	b.gem(Vector3(0, -4, -12))

	b.chaser(Vector3(0, -8, -27), 7, 3.0)
	b.key(Vector3(-4, -8, -31))
	b.gem(Vector3(-4, -8, -22))
	b.gem(Vector3(4, -8, -29))
	b.gem(Vector3(0, -3, -25))
	b.patroller(Vector3(4.5, -7, -23), Vector3(0, 5, 0), 4.0)
	b.ramp(Vector3(0, -8, -34), Vector3(0, 0, -42), 12)

	b.floor(0, -48, 12, 12, 0, floor_kind, 8.5)
	b.checkpoint(Vector3(0, 0, -43.5))
	b.gate(Vector3(0, 0, -45.5), 12)
	b.finish_at(Vector3(0, 0, -50))
