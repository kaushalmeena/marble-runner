extends LevelDef
## Introduces guards: avoid them, shield through them, then drop on one.


func _init() -> void:
	id = &"guard_duty"
	title = "Guard Duty"
	hint = "They only know one route. Learn it."
	gold_time = 20.0
	silver_time = 34.0


func build(b: LevelBuilder) -> void:
	b.start(Vector3(0, 0, 0))
	b.tip(Vector3(0, 0, 0), "Spiky guards send you back. Time your way past.")
	b.floor(0, -6, 8, 16)
	b.patroller(Vector3(-3, 0, -9), Vector3(6, 0, 0), 4.0)
	b.gem_line(Vector3(0, 0, -4), Vector3(0, 0, -12), 3)

	b.floor(0, -22, 8, 12)
	b.power_up(PowerUps.Kind.SHIELD, Vector3(0, 0, -18))
	b.patroller(Vector3(-3, 0, -22), Vector3(6, 0, 0), 3.0)
	b.patroller(Vector3(3, 0, -25.5), Vector3(-6, 0, 0), 3.0)
	b.gem(Vector3(-2.5, 0, -23.8))
	b.gem(Vector3(2.5, 0, -23.8))

	b.floor(0, -30, 8, 4, 0.8, LevelBuilder.Surface.FLOOR, 1.8)
	b.floor(0, -34, 8, 4, 1.6, LevelBuilder.Surface.FLOOR, 2.6)
	b.checkpoint(Vector3(0, 1.6, -34))
	b.tip(Vector3(0, 1.6, -34), "Drop onto a guard from above and it pops.")
	b.floor(0, -43, 8, 14)
	b.patroller(Vector3(-2.5, 0, -38.5), Vector3(5, 0, 0), 5.0)
	b.gem(Vector3(0, 0, -43))
	b.gem(Vector3(-3, 0, -46))
	b.gem(Vector3(3, 0, -46))
	b.finish_at(Vector3(0, 0, -48))
