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

const SAVE_PATH := "user://marble_runner.cfg"
const SAVE_SECTION := "progress"
const SAVE_KEY_BEST := "best_score"

## Points awarded per collected fruit, before the multiplier.
const POINTS_PER_PICKUP := 1
## Points for slipping past an obstacle by a hair.
const POINTS_PER_NEAR_MISS := 1
## Consecutive pickups needed for each extra multiplier step.
const STREAK_PER_MULTIPLIER := 5
const MAX_MULTIPLIER := 5

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

## Consecutive fruit collected without letting one slip past.
var streak: int = 0

## Score multiplier earned by the current streak.
var multiplier: int = 1:
	set(value):
		if multiplier == value:
			return
		multiplier = value
		multiplier_changed.emit(multiplier)

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
	_best_at_run_start = best_score


## True when the run that just ended beat the previous personal best.
func is_new_record() -> bool:
	return score > _best_at_run_start


## Scores a collected fruit, extending the streak and paying out at the
## current multiplier.
func collect_pickup() -> void:
	streak += 1
	multiplier = clampi(1 + streak / STREAK_PER_MULTIPLIER, 1, MAX_MULTIPLIER)
	add_score(POINTS_PER_PICKUP * multiplier)


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
	save_progress()


func load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	best_score = int(config.get_value(SAVE_SECTION, SAVE_KEY_BEST, 0))


func save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value(SAVE_SECTION, SAVE_KEY_BEST, best_score)
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("Could not save progress to %s (error %d)." % [SAVE_PATH, error])
