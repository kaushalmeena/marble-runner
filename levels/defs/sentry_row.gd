extends LevelDef
## Sentries that fire at a marble in range; a shield, and room to dodge.


func _init() -> void:
	id = &"sentry_row"
	title = "Sentry Row"
	hint = "They shoot slowly. Do not stand still."
	biome = preload("res://resources/biomes/foundry.tres")
	gold_time = 21.0
	silver_time = 34.0


func build(b: LevelBuilder) -> void:
	b.start(Vector3(0, 0, 0))
	b.floor(0, -30, 10, 64)
	b.tip(Vector3(0, 0, -3), "Sentries fire slow shots. Side-step them, or land on the sentry.")
	b.sentry(Vector3(-4, 0, -14), 11.0)
	b.gem(Vector3(3, 0, -10))
	b.gem(Vector3(0, 0, -16))
	b.power_up(PowerUps.Kind.SHIELD, Vector3(0, 0, -21))
	b.sentry(Vector3(4, 0, -27), 11.0)
	b.gem(Vector3(-3, 0, -27))
	b.checkpoint(Vector3(0, 0, -34))
	# The secret diamond: the sentry in the middle of the row is sitting on it.
	var keeper := b.sentry(Vector3(0, 0, -46), 10.0, 1.8)
	keeper.reveals = [b.secret(Vector3(0, 0, -46), true)]
	b.gem(Vector3(-4, 0, -42))
	b.gem(Vector3(4, 0, -50))
	b.sentry(Vector3(-4, 0, -56), 9.0)
	b.sentry(Vector3(4, 0, -56), 9.0)
	b.finish_at(Vector3(0, 0, -60))
