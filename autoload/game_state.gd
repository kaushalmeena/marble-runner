extends Node
## Owns the score for the current run and the persisted personal best.
##
## Nothing else in the project writes to these values directly: gameplay calls
## [method add_score], and the UI reacts to the signals below. That keeps the HUD
## and the menus free of any knowledge about how scoring works.

## Emitted whenever the live run score changes.
signal score_changed(score: int)
## Emitted when the personal best is beaten (during a run, not only at the end).
signal best_score_changed(best_score: int)
## Emitted when the pickup streak changes the score multiplier.
signal multiplier_changed(multiplier: int)
## Emitted when the furthest run gets further.
signal best_distance_changed(best_distance: float)
## Emitted when the coin purse changes.
signal coins_changed(coins: int)
## Emitted when a skin is bought.
signal skin_unlocked(id: StringName)
## Emitted when the equipped skin changes.
signal skin_selected(id: StringName)

const SAVE_PATH := "user://marble_runner.cfg"
const SAVE_SECTION := "progress"
const SAVE_KEY_BEST := "best_score"
const SAVE_KEY_BEST_DISTANCE := "best_distance"
const SAVE_KEY_COINS := "coins"
const SAVE_KEY_UNLOCKED := "unlocked_skins"
const SAVE_KEY_SKIN := "selected_skin"

## Points awarded per collected fruit, before the multiplier.
const POINTS_PER_PICKUP := 1
## Points for slipping past an obstacle by a hair.
const POINTS_PER_NEAR_MISS := 1
## Consecutive pickups needed for each extra multiplier step.
const STREAK_PER_MULTIPLIER := 5
const MAX_MULTIPLIER := 5

## Coins for each fruit. Deliberately not multiplied: the streak should pay out
## in score, so the shop stays on a predictable schedule rather than swinging
## wildly with how a single run went.
const COINS_PER_PICKUP := 1
## Distance, in units, worth one extra coin at the end of a run.
const UNITS_PER_BONUS_COIN := 100.0

var score: int = 0:
	set(value):
		if score == value:
			return
		score = value
		score_changed.emit(score)

var best_score: int = 0:
	set(value):
		if best_score == value:
			return
		best_score = value
		best_score_changed.emit(best_score)

## Distance covered in the most recent run, for the death screen.
var run_distance: float = 0.0

## Furthest distance ever reached, persisted between sessions.
var best_distance: float = 0.0:
	set(value):
		if is_equal_approx(best_distance, value):
			return
		best_distance = value
		best_distance_changed.emit(best_distance)

## Coins banked across all runs.
var coins: int = 0:
	set(value):
		var clamped := maxi(0, value)
		if coins == clamped:
			return
		coins = clamped
		coins_changed.emit(coins)

## Coins earned in the current run, for the death screen.
var run_coins: int = 0

## Skin ids the player owns. Free skins are always considered owned, so this
## only ever holds purchases.
var unlocked_skins: PackedStringArray = PackedStringArray()

## Equipped skin id.
var selected_skin: StringName = &"classic":
	set(value):
		if selected_skin == value:
			return
		selected_skin = value
		skin_selected.emit(selected_skin)

## Consecutive fruit collected without letting one slip past.
var streak: int = 0

## Score multiplier earned by the current streak.
var multiplier: int = 1:
	set(value):
		if multiplier == value:
			return
		multiplier = value
		multiplier_changed.emit(multiplier)

## Best distance as it stood when this run began, paired with the score below.
var _best_distance_at_run_start: float = 0.0

## Best score as it stood when this run began, so [method is_new_record] can
## still tell a record apart after [member best_score] has been promoted.
var _best_at_run_start: int = 0


func _ready() -> void:
	load_progress()


## Clears the run score. Call this when a new run begins.
func reset_run() -> void:
	score = 0
	run_distance = 0.0
	streak = 0
	multiplier = 1
	run_coins = 0
	_best_at_run_start = best_score
	_best_distance_at_run_start = best_distance


## True when the run that just ended beat the previous personal best.
func is_new_record() -> bool:
	return score > _best_at_run_start


## True when the run that just ended went further than any before it.
func is_new_distance_record() -> bool:
	return run_distance > _best_distance_at_run_start


## Scores a collected fruit, extending the streak and paying out at the
## current multiplier.
func collect_pickup() -> void:
	streak += 1
	multiplier = clampi(1 + streak / STREAK_PER_MULTIPLIER, 1, MAX_MULTIPLIER)
	add_score(POINTS_PER_PICKUP * multiplier)
	run_coins += COINS_PER_PICKUP
	coins += COINS_PER_PICKUP


## Scores a near miss. It pays the multiplier but does not extend the streak:
## the streak is about collecting, and rewarding both would let a player farm
## multipliers without touching a single fruit.
func score_near_miss() -> void:
	add_score(POINTS_PER_NEAR_MISS * multiplier)


## Ends the streak. Called when a fruit is allowed to scroll past uncollected.
func break_streak() -> void:
	streak = 0
	multiplier = 1


## Adds points and promotes them to the personal best as soon as they are earned,
## so the HUD can celebrate a new record mid-run.
func add_score(amount: int = POINTS_PER_PICKUP) -> void:
	score += amount
	if score > best_score:
		best_score = score


## Persists progress at the end of a run.
func commit_run() -> void:
	if score > best_score:
		best_score = score
	if run_distance > best_distance:
		best_distance = run_distance
	# Distance pays out at the end rather than in dribs during the run, so a
	# long careful run is worth something even without a big score.
	var distance_bonus := int(run_distance / UNITS_PER_BONUS_COIN)
	run_coins += distance_bonus
	coins += distance_bonus
	save_progress()


## True when the player owns [param skin], or it costs nothing.
func is_skin_unlocked(skin: MarbleSkin) -> bool:
	if skin == null:
		return false
	return skin.is_free() or unlocked_skins.has(String(skin.id))


## Spends coins on a skin. Returns false, changing nothing, when it is already
## owned or unaffordable.
func purchase_skin(skin: MarbleSkin) -> bool:
	if skin == null or is_skin_unlocked(skin) or coins < skin.price:
		return false
	coins -= skin.price
	unlocked_skins.append(String(skin.id))
	skin_unlocked.emit(skin.id)
	save_progress()
	return true


## Equips a skin the player owns. Returns whether it took.
func select_skin(skin: MarbleSkin) -> bool:
	if not is_skin_unlocked(skin):
		return false
	selected_skin = skin.id
	save_progress()
	return true


func load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	best_score = int(config.get_value(SAVE_SECTION, SAVE_KEY_BEST, 0))
	best_distance = float(config.get_value(SAVE_SECTION, SAVE_KEY_BEST_DISTANCE, 0.0))
	coins = int(config.get_value(SAVE_SECTION, SAVE_KEY_COINS, 0))
	unlocked_skins = PackedStringArray(
		config.get_value(SAVE_SECTION, SAVE_KEY_UNLOCKED, PackedStringArray()))
	selected_skin = StringName(config.get_value(SAVE_SECTION, SAVE_KEY_SKIN, "classic"))


func save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value(SAVE_SECTION, SAVE_KEY_BEST, best_score)
	config.set_value(SAVE_SECTION, SAVE_KEY_BEST_DISTANCE, best_distance)
	config.set_value(SAVE_SECTION, SAVE_KEY_COINS, coins)
	config.set_value(SAVE_SECTION, SAVE_KEY_UNLOCKED, unlocked_skins)
	config.set_value(SAVE_SECTION, SAVE_KEY_SKIN, String(selected_skin))
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("Could not save progress to %s (error %d)." % [SAVE_PATH, error])
