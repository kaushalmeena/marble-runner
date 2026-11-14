extends LevelDef
## Chasers hunting across tar, slowing traps, and the grip and shield that even it up.


func _init() -> void:
	id = &"mire"
	title = "Mire"
	hint = "They are quicker than you in the tar."
	biome = preload("res://resources/biomes/canyon.tres")
	gold_time = 27.0
	silver_time = 43.0


func build(b: LevelBuilder) -> void:
	b.start(Vector3(0, 0, 0))
	b.floor(0, -30, 16, 64)
	b.power_up(PowerUps.Kind.GRIP, Vector3(0, 0, -6))
	b.mud(0, -16, 16, 12)
	# The secret diamond: the first hunter is carrying it. Pop the hunter.
	var keeper := b.chaser(Vector3(0, 0, -17), 7.0, 3.2)
	keeper.reveals = [b.secret(Vector3(0, 0, -12), true)]
	b.gem(Vector3(-5, 0, -14))
	b.gem(Vector3(5, 0, -18))
	b.checkpoint(Vector3(0, 0, -26))
	b.power_up(PowerUps.Kind.SHIELD, Vector3(6, 0, -29))
	b.power_up(PowerUps.Kind.GRIP, Vector3(-6, 0, -29))
	b.mud(0, -41, 16, 14)
	b.chaser(Vector3(-4, 0, -41), 7.0, 3.0)
	b.chaser(Vector3(4, 0, -43), 7.0, 3.0)
	b.trap(PowerUps.Kind.SLOW, Vector3(0, 0, -36))
	b.trap(PowerUps.Kind.SLOW, Vector3(0, 0, -46))
	b.gem(Vector3(-6, 0, -38))
	b.gem(Vector3(6, 0, -44))
	b.gem(Vector3(0, 0, -41))
	b.finish_at(Vector3(0, 0, -58))
