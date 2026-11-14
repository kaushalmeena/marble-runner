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
	b.gem(Vector3(0, 0.5, -11.25))

	b.floor(0, -17, 6, 9)
	b.gem(Vector3(0, 0, -17))
	b.floor(0, -25.5, 6, 8, 0.8, LevelBuilder.Surface.FLOOR, 1.8)
	b.floor(0, -33.5, 6, 8, 1.6, LevelBuilder.Surface.FLOOR, 2.6)
	b.gem(Vector3(0, 0.8, -25.5))
	b.gem(Vector3(0, 1.6, -33.5))

	b.floor(0, -45, 8, 9, 1.6)
	b.checkpoint(Vector3(0, 1.6, -43))
	b.tip(Vector3(0, 1.6, -45), "Fall off and you come back at the last ring you touched.")
	b.floor(-6.5, -45, 3, 3, 1.6)
	b.floor(-11.5, -45, 3, 3, 1.6)
	b.gem(Vector3(-6.5, 1.6, -45))
	b.gem(Vector3(-11.5, 1.6, -45))
	b.floor(-20, -45, 9, 9, 1.6)
	b.gem(Vector3(-17.5, 1.6, -45))
	b.finish_at(Vector3(-21, 1.6, -45))
