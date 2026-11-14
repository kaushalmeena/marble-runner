extends LevelDef
## A timed bridge out to a key and back, a moving platform, a gate, and one last button.


func _init() -> void:
	id = &"switchyard_2"
	title = "Switchyard"
	hint = "The key is across a bridge that will not stay."
	biome = preload("res://resources/biomes/night.tres")
	gold_time = 60.0
	silver_time = 95.0


func build(b: LevelBuilder) -> void:
	b.start(Vector3(0, 0, 0))
	b.floor(0, -4, 8, 12)
	b.tip(Vector3(0, 0, -3), "The key is out to the right. The bridge to it is on a timer.")
	var spur := b.bridge(8, -7, 8, 4)
	b.button(Vector3(-2, 0, -7), [spur], 9.0)
	b.floor(15, -7, 6, 6)
	b.key(Vector3(15, 0, -6))
	# A second button on the far side, so a slow trip out is not a dead end.
	b.button(Vector3(16, 0, -8.5), [spur], 9.0)
	b.gem(Vector3(8, 0, -7))

	b.mover(Vector3(0, 0, -12.5), Vector2(4, 5), Vector3(0, 0, -10))
	b.floor(0, -30, 8, 10)
	b.checkpoint(Vector3(0, 0, -27.5))
	b.gem(Vector3(0, 0, -30))
	b.gate(Vector3(0, 0, -34), 8)
	b.floor(0, -40, 8, 10)
	var last := b.bridge(0, -50, 4, 10)
	b.button(Vector3(0, 0, -39), [last])
	b.gem(Vector3(0, 0, -50))
	b.floor(0, -60, 8, 10)
	# The finish used to stand here. Now it is a checkpoint, and the level
	# carries on: the second half is laid out as a trail.
	b.checkpoint(Vector3(0, 0, -61))
	var left := Trail.LEFT
	var t := Trail.new(b, Vector3(0, 0, -65), 0)
	t.bridge(12, 5.0, 2)
	t.run(6)
	t.secret_side(Trail.RIGHT)
	t.mover(8)
	t.run(6)
	t.turn(left)
	t.bridge(14, 5.5, 2)
	t.run(6)
	t.crumbles(3)
	t.run(5)
	t.mover(8)
	t.run(6)
	t.finish()
