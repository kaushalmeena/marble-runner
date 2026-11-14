extends LevelDef
## The finale: a boosted launch in low gravity, a chaser guarding the key, a
## portal up to a crumbling crossing that needs the double jump.


func _init() -> void:
	id = &"far_side"
	title = "Far Side"
	hint = "Everything at once, a long way from home."
	biome = preload("res://resources/biomes/moon.tres")
	gravity_scale = 0.35
	gold_time = 60.0
	silver_time = 95.0


func build(b: LevelBuilder) -> void:
	var thin := 0.5
	var floor_kind := LevelBuilder.Surface.FLOOR
	b.start(Vector3(0, 0, 0))
	b.floor(0, -3, 8, 10)
	b.boost_pad(Vector3(0, 0, -3), 0, 20)
	b.curved_ramp(Vector3(0, 0, -8), Vector3(0, 1.6, -14), 8)

	b.floor(0, -60, 14, 52)
	b.checkpoint(Vector3(0, 0, -62))
	b.power_up(PowerUps.Kind.SHIELD, Vector3(-4, 0, -60))
	b.chaser(Vector3(0, 0, -72), 8, 4.5)
	b.key(Vector3(0, 0, -76))
	b.gem(Vector3(-5, 0, -70))
	b.gem(Vector3(5, 0, -70))
	b.gem(Vector3(0, 0, -82))
	b.floor(0, -89, 4, 6)
	b.gate(Vector3(0, 0, -87), 4)

	b.floor(0, -97, 8, 10)
	b.checkpoint(Vector3(0, 0, -94))
	b.portal_pair(Vector3(0, 0, -99.5), 180, Vector3(0, 12, -110), 0)
	b.floor(0, -114, 8, 10, 12, floor_kind, thin)
	b.checkpoint(Vector3(0, 12, -112.5))
	b.power_up(PowerUps.Kind.DOUBLE_JUMP, Vector3(0, 12, -115))
	b.tip(Vector3(0, 12, -113), "The stones fall. Double jump if you come up short.")
	for stone in 3:
		var z := -127.0 - stone * 10.0
		b.crumble(0, z, 12, 0, Vector2(4.5, 4.5))
		b.gem(Vector3(0, 12, z))
	b.floor(0, -158, 10, 10, 12, floor_kind, thin)
	b.finish_at(Vector3(0, 12, -159))
