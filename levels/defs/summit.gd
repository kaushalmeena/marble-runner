extends LevelDef
## The last level: a staircase of separate steps spiralling round a tower.
## Every step is a jump, and the steps stop being trustworthy on the way up.


func _init() -> void:
	id = &"summit"
	title = "Summit"
	hint = "It is a long way down from the top."
	biome = preload("res://resources/biomes/dusk.tres")
	gold_time = 55.0
	silver_time = 90.0


func build(b: LevelBuilder) -> void:
	const STEPS := 26
	const RADIUS := 9.0
	const RISE := 0.7
	const TURN := 32.0
	b.start(Vector3(0, 0, 13), 0)
	b.tip(Vector3(0, 0, 13), "Up. Hold SPACE and keep turning with the tower.")
	b.floor(0, 0, 30, 30)
	var top := RISE * STEPS
	b.box(Vector3(0, top / 2.0 - 0.5, 0), Vector3(5, top - 1.0, 5), LevelBuilder.Surface.WALL)

	for step in STEPS:
		var angle := deg_to_rad(TURN * step)
		var y := RISE * (step + 1)
		var x := sin(angle) * RADIUS
		var z := cos(angle) * RADIUS
		var yaw := TURN * step
		if step % 8 == 7:
			# A wide, solid landing with a checkpoint: somewhere to breathe.
			b.box(Vector3(x, y - 0.25, z), Vector3(4.5, 0.5, 4.5), LevelBuilder.Surface.FLOOR, yaw)
			b.checkpoint(Vector3(x, y, z))
		elif step > 8 and step % 3 == 1:
			b.crumble(x, z, y, yaw, Vector2(3.6, 3.6))
		elif step > 14 and step % 4 == 2:
			b.box(Vector3(x, y - 0.25, z), Vector3(3.6, 0.5, 3.6), LevelBuilder.Surface.ICE, yaw)
		else:
			b.box(Vector3(x, y - 0.25, z), Vector3(3.6, 0.5, 3.6), LevelBuilder.Surface.FLOOR, yaw)
		if step % 3 == 0:
			b.gem(Vector3(x, y, z))

	b.power_up(PowerUps.Kind.FEATHER, Vector3(5, 0, 12))
	b.floor(0, 0, 11, 11, top + RISE, LevelBuilder.Surface.FLOOR, 0.5)
	b.finish_at(Vector3(0, top + RISE, 0))
