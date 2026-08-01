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

const SAVE_PATH := "user://marble_runner.cfg"
const SAVE_SECTION := "progress"
const SAVE_KEY_BEST := "best_score"

## Points awarded per collected fruit.
const POINTS_PER_PICKUP := 1

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


func _ready() -> void:
	load_progress()


## Clears the run score. Call this when a new run begins.
func reset_run() -> void:
	score = 0


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
