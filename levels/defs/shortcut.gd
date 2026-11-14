extends LevelDef
## Introduces portals, then uses one to carry a boost pad's speed onto a
## runway with a jump at the end.


func _init() -> void:
	id = &"shortcut"
	title = "Shortcut"
	hint = "Rings are doors. Speed goes through with you."
	biome = preload("res://resources/biomes/tundra.tres")
	gold_time = 20.0
	silver_time = 34.0


func build(b: LevelBuilder) -> void:
	var thin := 0.5
	var floor_kind := LevelBuilder.Surface.FLOOR
	b.start(Vector3(0, 0, 0))
	b.tip(Vector3(0, 0, 0), "Rings are doors. You come out as fast as you went in.")
	b.floor(0, -3, 8, 10)
	b.portal_pair(Vector3(0, 0, -6.5), 180, Vector3(29, 6, -39.5), 0)

	# Two lanes: the one you arrive in ends at a kerb, so coming through fast
	# does not carry you into the next ring before you have chosen to.
	b.floor(32, -44, 12, 12, 6, floor_kind, thin)
	b.wall(Vector3(26.2, 6, -49.8), Vector3(32, 6, -49.8))
	b.checkpoint(Vector3(29, 6, -41.5))
	b.gem(Vector3(29, 6, -44.5))
	b.gem(Vector3(29, 6, -47.5))
	b.tip(Vector3(30, 6, -43), "Hit the pad, then the ring. Do not brake.")
	b.boost_pad(Vector3(35, 6, -43.5), 0, 20)
	b.portal_pair(Vector3(35, 6, -48.5), 0, Vector3(-20.5, 2, -20), 90)

	b.floor(-34, -20, 30, 8, 2, floor_kind, thin)
	b.gem_line(Vector3(-28, 2, -20), Vector3(-44, 2, -20), 3)
	b.curved_ramp(Vector3(-49, 2, -20), Vector3(-55, 3.6, -20), 8)
	b.floor(-74, -20, 24, 10, 2, floor_kind, thin)
	b.gem(Vector3(-72, 2, -20))
	b.gem(Vector3(-76, 2, -18))
	b.finish_at(Vector3(-81, 2, -20))
