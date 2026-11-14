extends LevelDef
## Traps that slow, reverse and weigh down the marble; a shield turns them away.


func _init() -> void:
	id = &"booby_traps"
	title = "Booby Traps"
	hint = "Not every pickup is a present."
	biome = preload("res://resources/biomes/night.tres")
	gold_time = 23.0
	silver_time = 37.0


func build(b: LevelBuilder) -> void:
	b.start(Vector3(0, 0, 0))
	b.floor(0, -14, 8, 32)
	b.tip(Vector3(0, 0, -3), "Pickups in a dark bubble are traps. Go round them.")
	b.trap(PowerUps.Kind.SLOW, Vector3(-2, 0, -9))
	b.gem(Vector3(2, 0, -9))
	b.trap(PowerUps.Kind.DIZZY, Vector3(2, 0, -16))
	b.gem(Vector3(-2, 0, -16))
	b.trap(PowerUps.Kind.HEAVY, Vector3(0, 0, -22))
	b.gem(Vector3(-3, 0, -22))
	b.power_up(PowerUps.Kind.SHIELD, Vector3(3, 0, -26))
	b.tip(Vector3(0, 0, -27), "No way round the next one. A shield soaks it up.")
	# A beam too narrow to pass the trap sitting on it.
	b.floor(0, -38, 2.4, 16)
	b.trap(PowerUps.Kind.DIZZY, Vector3(0, 0, -35))
	b.gem(Vector3(0, 0, -41))
	b.floor(0, -54, 8, 16)
	b.checkpoint(Vector3(0, 0, -48))
	b.gem_ring(Vector3(0, 0, -55), 2.6, 4)
	b.trap(PowerUps.Kind.SLOW, Vector3(0, 0, -55))
	b.finish_at(Vector3(0, 0, -60))
