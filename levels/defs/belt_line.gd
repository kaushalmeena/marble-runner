extends LevelDef
## Conveyor belts: one to ride, one to fight, two that push sideways.


func _init() -> void:
	id = &"belt_line"
	title = "Belt Line"
	hint = "The floor moves. Go with it, then against it."
	biome = preload("res://resources/biomes/foundry.tres")
	gold_time = 22.0
	silver_time = 35.0


func build(b: LevelBuilder) -> void:
	b.start(Vector3(0, 0, 0))
	b.floor(0, -4, 8, 12)
	b.tip(Vector3(0, 0, -7), "Belts carry you the way their arrows point.")
	b.floor(0, -16, 4, 12)
	b.conveyor(Vector3(0, 0, -16), Vector2(4, 12), 0, 5)
	b.gem_line(Vector3(0, 0, -12), Vector3(0, 0, -20), 3)

	b.floor(0, -27, 10, 10)
	b.checkpoint(Vector3(0, 0, -25))
	b.tip(Vector3(0, 0, -29), "This one runs against you. Keep rolling.")
	b.floor(0, -38, 4, 12)
	b.conveyor(Vector3(0, 0, -38), Vector2(4, 12), 180, 4)
	b.gem(Vector3(0, 0, -35))
	b.gem(Vector3(0, 0, -41))

	b.floor(0, -49, 10, 10)
	b.checkpoint(Vector3(0, 0, -47))
	# Two belts across the path, pushing opposite ways, toward the edges.
	b.floor(0, -62, 8, 16)
	b.conveyor(Vector3(0, 0, -58), Vector2(4, 8), 90, 5)
	b.conveyor(Vector3(0, 0, -66), Vector2(4, 8), -90, 5)
	b.gem(Vector3(0, 0, -58))
	b.gem(Vector3(0, 0, -66))
	b.floor(0, -75, 8, 10)
	b.finish_at(Vector3(0, 0, -76))
