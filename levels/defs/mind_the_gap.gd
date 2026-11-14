extends LevelDef
## Teaches the jump: a gap, two steps, a wider gap, then stepping stones.


func _init() -> void:
	id = &"mind_the_gap"
	title = "Mind the Gap"
	hint = "Space jumps. Hold it to keep hopping."
	gold_time = 17.0
	silver_time = 30.0


func build(b: LevelBuilder) -> void:
	b.start(Vector3(0, 0, 0))
	b.tip(Vector3(0, 0, 0), "SPACE jumps. You can steer in the air.")
	b.floor(0, -4, 6, 12)
	b.gem(Vector3(0, 0, -7))
	b.gem(Vector3(0, 0.5, -11))

	b.floor(0, -16.5, 6, 9)
	b.gem(Vector3(0, 0, -16.5))
	b.floor(0, -25, 6, 8, 0.8, LevelBuilder.Surface.FLOOR, 1.8)
	b.floor(0, -33, 6, 8, 1.6, LevelBuilder.Surface.FLOOR, 2.6)
	b.gem(Vector3(0, 0.8, -25))
	b.gem(Vector3(0, 1.6, -33))

	b.floor(0, -44.5, 8, 9, 1.6)
	b.checkpoint(Vector3(0, 1.6, -42.5))
	b.tip(Vector3(0, 1.6, -44.5), "Fall off and you come back at the last ring you touched.")
	b.floor(-8, -44.5, 4, 4, 1.6)
	b.floor(-14, -44.5, 4, 4, 1.6)
	b.gem(Vector3(-8, 1.6, -44.5))
	b.gem(Vector3(-14, 1.6, -44.5))
	b.floor(-22.5, -44.5, 9, 9, 1.6)
	b.gem(Vector3(-20, 1.6, -44.5))
	b.finish_at(Vector3(-24, 1.6, -44.5))
