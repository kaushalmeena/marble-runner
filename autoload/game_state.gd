extends Node
## Owns the player's progress: which levels are beaten and how fast, the coin
## purse, and the skins.
##
## Nothing else in the project writes to these values directly. Gameplay
## reports a finished level through [method complete_level], and the UI reads.

## Emitted when the coin purse changes.
signal coins_changed(coins: int)
## Emitted when a skin is bought.
signal skin_unlocked(id: StringName)
## Emitted when the equipped skin changes.
signal skin_selected(id: StringName)

const SAVE_PATH := "user://marble_runner.cfg"
const SAVE_SECTION := "progress"
const SAVE_KEY_COINS := "coins"
const SAVE_KEY_UNLOCKED := "unlocked_skins"
const SAVE_KEY_SKIN := "selected_skin"
const SAVE_KEY_TIMES := "best_times"
const SAVE_KEY_UNLOCK_ALL := "all_unlocked"
const SAVE_KEY_PAGE := "level_page"

## Coins for each gem, paid every time a level is finished. Replaying is the
## steady income.
const COINS_PER_GEM := 1
## Coins for each star earned for the first time. This is the big payout, and
## it can only be collected once per star.
const COINS_PER_NEW_STAR := 25

## When false nothing is written to disk. Test harnesses turn this off so an
## automated run cannot overwrite a real player's times.
var persist: bool = true

## Level played next, as an index into [LevelCatalog].
var current_level: int = 0

## Page of the level select last looked at, so it reopens where it was left.
## Negative until the player has opened it once.
var level_page: int = -1

## Coins banked across all runs.
var coins: int = 0:
	set(value):
		var clamped := maxi(0, value)
		if coins == clamped:
			return
		coins = clamped
		coins_changed.emit(coins)

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

## Best finishing time per level id, in seconds. A level with no entry has not
## been finished.
var _best_times: Dictionary = {}
## Set by the cheat that opens every level. Saved, so it sticks.
var _all_unlocked: bool = false


func _ready() -> void:
	load_progress()


## Best time for [param level], or a negative number if it is unbeaten.
func best_time(level: LevelDef) -> float:
	return float(_best_times.get(String(level.id), -1.0))


func is_completed(level: LevelDef) -> bool:
	return best_time(level) >= 0.0


## Stars held on [param level], 0..3.
func stars(level: LevelDef) -> int:
	var time := best_time(level)
	return level.stars_for(time) if time >= 0.0 else 0


func total_stars() -> int:
	var total := 0
	for level in LevelCatalog.all():
		total += stars(level)
	return total


## A level opens once the one before it has been finished.
func is_unlocked(index: int) -> bool:
	if _all_unlocked:
		return true
	return index <= 0 or is_completed(LevelCatalog.at(index - 1))


## Index of the first level not yet finished, or the last level if all are.
func next_unbeaten() -> int:
	for index in LevelCatalog.count():
		if not is_completed(LevelCatalog.at(index)):
			return index
	return LevelCatalog.count() - 1


## Records a finished level and pays out. Returns what happened, for the
## results screen: [code]stars[/code], [code]new_stars[/code],
## [code]new_best[/code], [code]previous_best[/code] and [code]coins[/code].
func complete_level(level: LevelDef, time: float, gem_count: int) -> Dictionary:
	var previous := best_time(level)
	var stars_before := stars(level)
	var is_best := previous < 0.0 or time < previous
	if is_best:
		_best_times[String(level.id)] = time
	var stars_now := level.stars_for(time)
	var new_stars := maxi(0, stars_now - stars_before)
	var earned := gem_count * COINS_PER_GEM + new_stars * COINS_PER_NEW_STAR
	coins += earned
	save_progress()
	return {
		"stars": stars_now,
		"new_stars": new_stars,
		"new_best": is_best,
		"previous_best": previous,
		"coins": earned,
	}


## What a finished run that must not count reports to the results screen:
## no stars, no coins, nothing saved.
func unrecorded_outcome(level: LevelDef) -> Dictionary:
	return {
		"stars": 0,
		"new_stars": 0,
		"new_best": false,
		"previous_best": best_time(level),
		"coins": 0,
		"cheated": true,
	}


## Opens every level, or with [param open] false goes back to unlocking them
## one at a time.
func unlock_all(open: bool = true) -> void:
	_all_unlocked = open
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
	coins = int(config.get_value(SAVE_SECTION, SAVE_KEY_COINS, 0))
	unlocked_skins = PackedStringArray(
		config.get_value(SAVE_SECTION, SAVE_KEY_UNLOCKED, PackedStringArray()))
	selected_skin = StringName(config.get_value(SAVE_SECTION, SAVE_KEY_SKIN, "classic"))
	var times: Variant = config.get_value(SAVE_SECTION, SAVE_KEY_TIMES, {})
	if times is Dictionary:
		_best_times = times
	_all_unlocked = bool(config.get_value(SAVE_SECTION, SAVE_KEY_UNLOCK_ALL, false))
	level_page = int(config.get_value(SAVE_SECTION, SAVE_KEY_PAGE, -1))


func save_progress() -> void:
	if not persist:
		return
	var config := ConfigFile.new()
	# Load first so keys this version does not know about survive the write.
	config.load(SAVE_PATH)
	config.set_value(SAVE_SECTION, SAVE_KEY_COINS, coins)
	config.set_value(SAVE_SECTION, SAVE_KEY_UNLOCKED, unlocked_skins)
	config.set_value(SAVE_SECTION, SAVE_KEY_SKIN, String(selected_skin))
	config.set_value(SAVE_SECTION, SAVE_KEY_TIMES, _best_times)
	config.set_value(SAVE_SECTION, SAVE_KEY_UNLOCK_ALL, _all_unlocked)
	config.set_value(SAVE_SECTION, SAVE_KEY_PAGE, level_page)
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("Could not save progress to %s (error %d)." % [SAVE_PATH, error])
