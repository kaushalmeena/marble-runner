class_name Hud
extends Control
## Run HUD: score, personal best, distance and a speed meter.
##
## The HUD is read-only. The old ScoreBoard owned an [code]increase_score()[/code]
## method that mutated the global score, which meant gameplay had to reach into
## the UI to score a point. Here the score lives in [GameState] and the HUD only
## reacts to it.

## How long the new-record badge stays on screen.
const RECORD_BADGE_SECONDS := 1.8

@onready var _score_value: Label = %ScoreValue
@onready var _best_value: Label = %BestValue
@onready var _distance_value: Label = %DistanceValue
@onready var _speed_bar: ProgressBar = %SpeedBar
@onready var _record_badge: Control = %RecordBadge
@onready var _crash_flash: ColorRect = %CrashFlash

var _track: Track = null
var _shown_distance: int = -1
var _record_announced: bool = false


func _ready() -> void:
	GameState.score_changed.connect(_on_score_changed)
	GameState.best_score_changed.connect(_on_best_score_changed)
	_score_value.text = str(GameState.score)
	_best_value.text = str(GameState.best_score)
	_record_badge.modulate.a = 0.0
	_record_badge.hide()
	_crash_flash.color.a = 0.0
	# Nothing to poll until a track is bound.
	set_process(false)


## Gives the HUD the track to read distance and speed from. Polling these once
## per rendered frame is cheaper than emitting a signal every physics tick for
## values that only ever feed a label and a bar.
func bind_track(track: Track) -> void:
	_track = track
	set_process(track != null)


func _process(_delta: float) -> void:
	var metres := int(_track.distance)
	if metres != _shown_distance:
		_shown_distance = metres
		_distance_value.text = "%d m" % metres
	_speed_bar.value = _track.speed_ratio()


## Scale punch on the score, so a pickup registers even without audio.
func pop_score() -> void:
	_score_value.pivot_offset = _score_value.size * 0.5
	var tween := create_tween()
	tween.tween_property(_score_value, "scale", Vector2(1.3, 1.3), 0.07)
	tween.tween_property(_score_value, "scale", Vector2.ONE, 0.16) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Red screen flash on death.
func show_crash() -> void:
	var tween := create_tween()
	tween.tween_property(_crash_flash, "color:a", 0.5, 0.07)
	tween.tween_property(_crash_flash, "color:a", 0.0, 0.42)


func _on_score_changed(score: int) -> void:
	_score_value.text = str(score)


func _on_best_score_changed(best_score: int) -> void:
	_best_value.text = str(best_score)
	# GameState promotes the best score the moment it is beaten, so the badge can
	# fire mid-run. Only announce it once per run, not on every later pickup.
	if _record_announced or _track == null or GameState.score <= 0:
		return
	_record_announced = true
	_announce_record()


func _announce_record() -> void:
	_record_badge.show()
	var tween := create_tween()
	tween.tween_property(_record_badge, "modulate:a", 1.0, 0.2)
	tween.tween_interval(RECORD_BADGE_SECONDS)
	tween.tween_property(_record_badge, "modulate:a", 0.0, 0.4)
	tween.tween_callback(_record_badge.hide)
