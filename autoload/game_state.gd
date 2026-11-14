extends Node
## Owns the player's progress: which levels are beaten and how fast, which
## secret diamonds are found, the purse of gems, and the skins.
##
## Nothing else in the project writes to these values directly. Gameplay
## reports a finished level through [method complete_level], and the UI reads.

## Emitted when the purse changes.
signal gems_changed(gems: int)
## Emitted when a skin is bought.
signal skin_unlocked(id: StringName)
## Emitted when the equipped skin changes.
signal skin_selected(id: StringName)

const SAVE_PATH := "user://marble_runner.cfg"
const SAVE_SECTION := "progress"
# The purse was once counted in coins; the key is kept so old saves carry over.
const SAVE_KEY_GEMS := "coins"
const SAVE_KEY_SECRETS := "secret_diamonds"
const SAVE_KEY_UNLOCKED := "unlocked_skins"
const SAVE_KEY_SKIN := "selected_skin"
const SAVE_KEY_TIMES := "best_times"
const SAVE_KEY_UNLOCK_ALL := "all_unlocked"
const SAVE_KEY_PAGE := "level_page"

## Every gem collected is banked when the level is finished, every time.
## Replaying is the steady income.
## On top of that, gems for each star earned for the first time, and for a
## level's secret diamond the first time it is brought home. These are the big
## payouts, and each can only be collected once.
const GEMS_PER_NEW_STAR := 25
const GEMS_PER_SECRET := 50

## When false nothing is written to disk. Test harnesses turn this off so an
## automated run cannot overwrite a real player's times.
var persist: bool = true

## Level played next, as an index into [LevelCatalog].
var current_level: int = 0

## Page of the level select last looked at, so it reopens where it was left.
## Negative until the player has opened it once.
var level_page: int = -1

## Gems banked across all runs. This is what the shop is priced in.
var gems: int = 0:
	set(value):
		var clamped := maxi(0, value)
		if gems == clamped:
			return
		gems = clamped
		gems_changed.emit(gems)

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
## Ids of the levels whose secret diamond has been found and carried to the finish.
var _secrets := PackedStringArray()


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


## True once [param level]'s secret diamond has been brought to the finish.
func has_secret(level: LevelDef) -> bool:
	return _secrets.has(String(level.id))


func total_secrets() -> int:
	var total := 0
	for level in LevelCatalog.all():
		if has_secret(level):
			total += 1
	return total


## Records a finished level and pays out. [param secret_found] is whether the
## secret diamond was picked up on this run. Returns what happened, for the
## results screen: [code]stars[/code], [code]new_stars[/code],
## [code]new_best[/code], [code]previous_best[/code], [code]gems[/code] and
## [code]new_secret[/code].
func complete_level(level: LevelDef, time: float, gem_count: int,
		secret_found: bool = false) -> Dictionary:
	var previous := best_time(level)
	var stars_before := stars(level)
	var is_best := previous < 0.0 or time < previous
	if is_best:
		_best_times[String(level.id)] = time
	var stars_now := level.stars_for(time)
	var new_stars := maxi(0, stars_now - stars_before)
	var new_secret := secret_found and not has_secret(level)
	if new_secret:
		_secrets.append(String(level.id))
	var earned := gem_count + new_stars * GEMS_PER_NEW_STAR + (
		GEMS_PER_SECRET if new_secret else 0)
	gems += earned
	save_progress()
	return {
		"stars": stars_now,
		"new_stars": new_stars,
		"new_best": is_best,
		"previous_best": previous,
		"gems": earned,
		"new_secret": new_secret,
	}


## What a finished run that must not count reports to the results screen:
## no stars, no gems, no secret, nothing saved.
func unrecorded_outcome(level: LevelDef) -> Dictionary:
	return {
		"stars": 0,
		"new_stars": 0,
		"new_best": false,
		"previous_best": best_time(level),
		"gems": 0,
		"new_secret": false,
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


## Spends gems on a skin. Returns false, changing nothing, when it is already
## owned or unaffordable.
func purchase_skin(skin: MarbleSkin) -> bool:
	if skin == null or is_skin_unlocked(skin) or gems < skin.price:
		return false
	gems -= skin.price
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
	gems = int(config.get_value(SAVE_SECTION, SAVE_KEY_GEMS, 0))
	_secrets = PackedStringArray(
		config.get_value(SAVE_SECTION, SAVE_KEY_SECRETS, PackedStringArray()))
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
	config.set_value(SAVE_SECTION, SAVE_KEY_GEMS, gems)
	config.set_value(SAVE_SECTION, SAVE_KEY_SECRETS, _secrets)
	config.set_value(SAVE_SECTION, SAVE_KEY_UNLOCKED, unlocked_skins)
	config.set_value(SAVE_SECTION, SAVE_KEY_SKIN, String(selected_skin))
	config.set_value(SAVE_SECTION, SAVE_KEY_TIMES, _best_times)
	config.set_value(SAVE_SECTION, SAVE_KEY_UNLOCK_ALL, _all_unlocked)
	config.set_value(SAVE_SECTION, SAVE_KEY_PAGE, level_page)
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("Could not save progress to %s (error %d)." % [SAVE_PATH, error])
