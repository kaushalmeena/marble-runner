extends LevelDef
## A climb in heavy gravity: a super jump up a wall, a fan to the next ledge, and stones that fall fast.


func _init() -> void:
	id = &"lead_boots"
	title = "Lead Boots"
	hint = "Heavy, and a long way up."
	biome = preload("res://resources/biomes/foundry.tres")
	gravity_scale = 1.4
	gold_time = 15.0
	silver_time = 24.0


func build(b: LevelBuilder) -> void:
	var floor_kind := LevelBuilder.Surface.FLOOR
	b.start(Vector3(0, 0, 0))
	b.floor(0, -4, 8, 12)
	b.power_up(PowerUps.Kind.SUPER_JUMP, Vector3(0, 0, -5))
	b.tip(Vector3(0, 0, -3), "Too heavy for that wall. Take the spring first.")
	b.floor(0, -15, 8, 10, 2.5, floor_kind, 3.5)
	b.gem(Vector3(0, 2.5, -14))
	b.checkpoint(Vector3(0, 2.5, -17))
	b.floor(0, -24, 6, 8, 2.5, floor_kind, 3.5)
	b.fan(Vector3(0, 2.5, -24), 8.0)
	b.gem(Vector3(0, 5.2, -24))
	b.tip(Vector3(0, 2.5, -20.5), "The fan lifts even a heavy marble. Ride it up and roll off the top.")
	b.floor(0, -33, 8, 10, 5.5, floor_kind, 1.0)
	b.checkpoint(Vector3(0, 5.5, -31))
	b.crumble(0, -39.5, 5.5)
	b.gem(Vector3(0, 5.5, -39.5))
	b.crumble(0, -42.5, 5.5)
	b.gem(Vector3(0, 5.5, -42.5))
	b.floor(0, -49, 8, 10, 5.5)
	b.finish_at(Vector3(0, 5.5, -51))
