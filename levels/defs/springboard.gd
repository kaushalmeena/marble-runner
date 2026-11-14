extends LevelDef
## Introduces the double jump: a wall, a long gap, a spring with a second
## jump at the top, then hops between islands at different heights.


func _init() -> void:
	id = &"springboard"
	title = "Springboard"
	hint = "One jump is never quite enough."
	biome = preload("res://resources/biomes/desert.tres")
	gold_time = 24.0
	silver_time = 40.0


func build(b: LevelBuilder) -> void:
	var thin := 0.5
	var floor_kind := LevelBuilder.Surface.FLOOR
	var double_jump := PowerUps.Kind.DOUBLE_JUMP
	b.start(Vector3(0, 0, 0))
	b.floor(0, -3, 10, 10)
	b.power_up(double_jump, Vector3(0, 0, -4))
	b.tip(Vector3(0, 0, -2), "Use DOUBLE JUMP, then press SPACE again in mid-air.")
	b.floor(0, -13, 8, 8, 2.2, floor_kind, 3.2)
	b.gem(Vector3(-2, 2.2, -13))
	b.gem(Vector3(2, 2.2, -13))

	b.floor(0, -27, 8, 8, 2.2, floor_kind, thin)
	b.checkpoint(Vector3(0, 2.2, -25))
	b.power_up(double_jump, Vector3(0, 2.2, -26.5))
	b.gem(Vector3(-2.5, 2.2, -27))
	b.bounce_pad(Vector3(0, 2.2, -29.5), 15)
	b.tip(Vector3(0, 2.2, -27), "Spring up, then jump again at the top.")
	b.floor(0, -38, 8, 8, 8, floor_kind, thin)
	b.checkpoint(Vector3(0, 8, -36))
	b.gem(Vector3(0, 8, -39))

	b.floor(10, -38, 6, 6, 6, floor_kind, thin)
	b.power_up(double_jump, Vector3(10, 6, -38))
	b.floor(20, -38, 6, 6, 8, floor_kind, thin)
	b.gem(Vector3(20, 8, -38))
	b.floor(30, -38, 8, 8, 8, floor_kind, thin)
	b.finish_at(Vector3(31, 8, -38))
