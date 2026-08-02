class_name Hud
extends Control
## Run HUD: score cluster top left, run telemetry top right, centre kept clear.
##
## The HUD is read-only. The old ScoreBoard owned an [code]increase_score()[/code]
## method that mutated the global score, which meant gameplay had to reach into
## the UI to score a point. Here the score lives in [GameState], the power-up
## timers live in [PowerUpManager], and the HUD only ever reacts and reads.

## How long the new-record badge stays on screen.
const RECORD_BADGE_SECONDS := 1.8
## Tint for the speed meter, matching the marble.
const SPEED_COLOR := Color(0.42, 0.74, 1.0)

@onready var _score_value: Label = %ScoreValue
@onready var _best_value: Label = %BestValue
@onready var _distance_value: Label = %DistanceValue
@onready var _speed_bar: ProgressBar = %SpeedBar
@onready var _record_badge: Label = %RecordBadge
@onready var _multiplier_value: Label = %MultiplierValue
@onready var _countdown: Label = %Countdown
@onready var _near_miss_toast: Label = %NearMissToast
@onready var _crash_flash: ColorRect = %CrashFlash

var _track: Track = null
var _power_ups: PowerUpManager = null
var _chips: Dictionary[int, PanelContainer] = {}
var _shown_distance: int = -1
var _record_announced: bool = false


func _ready() -> void:
	_chips = {
		PowerUps.Kind.SHIELD: %ShieldChip,
		PowerUps.Kind.MAGNET: %MagnetChip,
		PowerUps.Kind.SLOW_MO: %SlowChip,
	}
	for kind: int in _chips:
		_tint_chip(_chips[kind], PowerUps.color(kind))
		_chips[kind].hide()

	_tint_bar(_speed_bar, SPEED_COLOR)
	GameState.score_changed.connect(_on_score_changed)
	GameState.best_score_changed.connect(_on_best_score_changed)
	GameState.multiplier_changed.connect(_on_multiplier_changed)
	_score_value.text = str(GameState.score)
	_best_value.text = str(GameState.best_score)
	_record_badge.hide()
	_countdown.hide()
	_near_miss_toast.hide()
	_multiplier_value.visible = GameState.multiplier > 1
	_crash_flash.color.a = 0.0
	# Nothing to poll until a track is bound.
	set_process(false)


## Gives the HUD the run objects to read from. Polling these once per rendered
## frame is cheaper than emitting a signal every physics tick for values that
## only ever feed a label and a couple of bars.
func bind_run(track: Track, power_ups: PowerUpManager) -> void:
	_track = track
	_power_ups = power_ups
	if power_ups != null:
		power_ups.activated.connect(_on_power_up_activated)
		power_ups.expired.connect(_on_power_up_expired)
	set_process(track != null)


func _process(_delta: float) -> void:
	var metres := int(_track.distance)
	if metres != _shown_distance:
		_shown_distance = metres
		_distance_value.text = "%d m" % metres
	_speed_bar.value = _track.speed_ratio()
	if _power_ups == null:
		return
	for kind: int in _chips:
		var chip: PanelContainer = _chips[kind]
		if chip.visible:
			(chip.get_node("Column/Bar") as ProgressBar).value = _power_ups.fraction_left(kind)


## Scale punch on the score, so a pickup registers even without audio.
func pop_score() -> void:
	_score_value.pivot_offset = _score_value.size * 0.5
	var tween := create_tween()
	tween.tween_property(_score_value, "scale", Vector2(1.22, 1.22), 0.07)
	tween.tween_property(_score_value, "scale", Vector2.ONE, 0.16) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Red screen flash on death.
func show_crash() -> void:
	var tween := create_tween()
	tween.tween_property(_crash_flash, "color:a", 0.5, 0.07)
	tween.tween_property(_crash_flash, "color:a", 0.0, 0.42)


## Brief white flash when the shield eats a hit, so the save is legible.
func show_shield_save() -> void:
	_crash_flash.color = Color(0.55, 0.85, 1.0, 0.0)
	var tween := create_tween()
	tween.tween_property(_crash_flash, "color:a", 0.4, 0.06)
	tween.tween_property(_crash_flash, "color:a", 0.0, 0.3)
	tween.tween_callback(func() -> void: _crash_flash.color = Color(0.78, 0.09, 0.09, 0.0))


## Shows one step of the start countdown, punched in and faded out.
func show_countdown(text: String) -> void:
	_countdown.text = text
	_countdown.pivot_offset = _countdown.size * 0.5
	_countdown.modulate.a = 1.0
	_countdown.scale = Vector2(1.6, 1.6)
	_countdown.show()
	var tween := create_tween()
	tween.tween_property(_countdown, "scale", Vector2.ONE, 0.22) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func hide_countdown() -> void:
	var tween := create_tween()
	tween.tween_property(_countdown, "modulate:a", 0.0, 0.25)
	tween.tween_callback(_countdown.hide)


## Brief toast when an obstacle is dodged by a hair.
func show_near_miss() -> void:
	_near_miss_toast.modulate.a = 1.0
	_near_miss_toast.show()
	var tween := create_tween()
	tween.tween_interval(0.35)
	tween.tween_property(_near_miss_toast, "modulate:a", 0.0, 0.3)
	tween.tween_callback(_near_miss_toast.hide)


func _on_score_changed(score: int) -> void:
	_score_value.text = str(score)


func _on_multiplier_changed(multiplier: int) -> void:
	_multiplier_value.text = "x%d" % multiplier
	_multiplier_value.visible = multiplier > 1


func _on_best_score_changed(best_score: int) -> void:
	_best_value.text = str(best_score)
	# GameState promotes the best score the moment it is beaten, so the badge can
	# fire mid-run. Only announce it once per run, not on every later pickup.
	if _record_announced or _track == null or GameState.score <= 0:
		return
	_record_announced = true
	_announce_record()


func _announce_record() -> void:
	_record_badge.modulate.a = 0.0
	_record_badge.show()
	var tween := create_tween()
	tween.tween_property(_record_badge, "modulate:a", 1.0, 0.2)
	tween.tween_interval(RECORD_BADGE_SECONDS)
	tween.tween_property(_record_badge, "modulate:a", 0.0, 0.4)
	tween.tween_callback(_record_badge.hide)


func _on_power_up_activated(kind: PowerUps.Kind, _duration: float) -> void:
	var chip: PanelContainer = _chips.get(kind)
	if chip == null:
		return
	(chip.get_node("Column/Bar") as ProgressBar).value = 1.0
	chip.show()


func _on_power_up_expired(kind: PowerUps.Kind) -> void:
	var chip: PanelContainer = _chips.get(kind)
	if chip != null:
		chip.hide()


func _tint_chip(chip: PanelContainer, color: Color) -> void:
	(chip.get_node("Column/Label") as Label).add_theme_color_override(&"font_color", color)
	_tint_bar(chip.get_node("Column/Bar") as ProgressBar, color)


## The theme's fill box is white so it can be tinted per use. Duplicating it
## keeps each bar's colour local instead of mutating the shared theme resource.
func _tint_bar(bar: ProgressBar, color: Color) -> void:
	var fill := bar.get_theme_stylebox(&"fill").duplicate() as StyleBoxFlat
	fill.bg_color = color
	bar.add_theme_stylebox_override(&"fill", fill)
