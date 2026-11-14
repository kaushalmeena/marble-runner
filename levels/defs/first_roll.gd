extends LevelDef
## Teaches rolling, turning and what gems are for. Kerbs everywhere: nobody
## should fall off the first level.


func _init() -> void:
	id = &"first_roll"
	title = "First Roll"
	hint = "Find your feet. Well, your roll."
	gold_time = 12.0
	silver_time = 20.0


func build(b: LevelBuilder) -> void:
	b.start(Vector3(0, 0, 1))
	b.tip(Vector3(0, 0, 1), "W A S D or the arrow keys roll the marble.")
	b.floor(0, -7, 8, 22)
	b.wall(Vector3(-3.8, 0, 3.8), Vector3(3.8, 0, 3.8))
	b.wall(Vector3(-3.8, 0, 3.8), Vector3(-3.8, 0, -25.8))
	b.wall(Vector3(3.8, 0, 3.8), Vector3(3.8, 0, -18))
	b.gem_line(Vector3(0, 0, -4), Vector3(0, 0, -16), 4)

	b.tip(Vector3(0, 0, -15), "Q and E turn the camera. It also follows you on its own.", 4.0)
	b.floor(8, -22, 24, 8)
	b.wall(Vector3(-3.8, 0, -25.8), Vector3(20, 0, -25.8))
	b.wall(Vector3(3.8, 0, -18.2), Vector3(20, 0, -18.2))
	b.gem_line(Vector3(4, 0, -22), Vector3(16, 0, -22), 4)

	b.ramp(Vector3(20, 0, -22), Vector3(28, 2, -22), 8)
	b.tip(Vector3(18, 0, -22), "Collect every gem to open the finish.", 4.0)
	b.floor(34, -22, 12, 12, 2)
	b.wall(Vector3(39.8, 2, -27.8), Vector3(39.8, 2, -16.2))
	b.wall(Vector3(28, 2, -27.8), Vector3(39.8, 2, -27.8))
	b.wall(Vector3(28, 2, -16.2), Vector3(39.8, 2, -16.2))
	b.gem(Vector3(31, 2, -19))
	b.gem(Vector3(31, 2, -25))
	b.finish_at(Vector3(36, 2, -22))
