class_name ResultsCard
extends Control
## The level-complete overlay: time, stars, payout and where to go next.

signal next_pressed
signal retry_pressed
signal levels_pressed

var _title: Label
var _time: Label
var _detail: Label
var _targets: Label
var _payout: Label
var _stars: StarRow
var _next: Button
var _retry: Button
var _dim: ColorRect
var _center: Control


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	hide()
	_dim = Ui.shade(Color(0.02, 0.04, 0.08, 0.6))
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_center = center
	var card := PanelContainer.new()
	center.add_child(card)
	var box := Ui.column(2)
	card.add_child(box)

	box.add_child(Ui.label("LEVEL COMPLETE", &"CaptionLabel", HORIZONTAL_ALIGNMENT_CENTER))
	_title = Ui.label("", &"HeadingLabel", HORIZONTAL_ALIGNMENT_CENTER)
	_title.custom_minimum_size.x = 420.0
	box.add_child(_title)
	_stars = StarRow.new(44.0)
	_stars.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(Ui.gap(6))
	box.add_child(_stars)
	box.add_child(Ui.gap(6))
	_time = Ui.label("", &"ScoreLabel", HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(_time)
	_detail = Ui.label("", &"AccentLabel", HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(_detail)
	_targets = Ui.label("", &"CaptionLabel", HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(_targets)
	_payout = Ui.label("", &"HintLabel", HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(_payout)
	box.add_child(Ui.gap(14))

	var buttons := Ui.column(12)
	buttons.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_next = Ui.button("Next Level", 340.0, Icon.Kind.NEXT, &"PrimaryButton")
	_retry = Ui.button("Retry", 164.0, Icon.Kind.RESTART)
	var levels := Ui.button("Levels", 164.0, Icon.Kind.LEVELS)
	_next.pressed.connect(next_pressed.emit)
	_retry.pressed.connect(retry_pressed.emit)
	levels.pressed.connect(levels_pressed.emit)
	var pair := Ui.row(12)
	pair.add_child(_retry)
	pair.add_child(levels)
	buttons.add_child(_next)
	buttons.add_child(pair)
	box.add_child(buttons)


## Fills the card from a finished run. [param outcome] is what
## [code]GameState.complete_level[/code] returned.
func present(level: LevelDef, time: float, outcome: Dictionary, has_next: bool) -> void:
	_title.text = level.title
	_time.text = LevelDef.format_time(time)
	var previous: float = outcome.previous_best
	if outcome.get("cheated", false):
		_detail.text = "CHEATS USED   NOT RECORDED"
	elif outcome.new_best and previous >= 0.0:
		_detail.text = "NEW BEST   -%.2fs" % (previous - time)
	elif outcome.new_best:
		_detail.text = "FIRST CLEAR"
	else:
		_detail.text = "BEST  %s" % LevelDef.format_time(previous)
	_targets.text = "GOLD %s      SILVER %s" % [
		LevelDef.format_time(level.gold_time), LevelDef.format_time(level.silver_time)]
	_payout.text = "+%d gems" % outcome.gems
	if outcome.get("new_secret", false):
		_payout.text = "SECRET DIAMOND FOUND      " + _payout.text
	# Disabled rather than removed on the last level, so the card keeps its size.
	_next.disabled = not has_next
	_next.text = "Next Level" if has_next else "All Levels Clear"
	show()
	Ui.fade_in(_dim, 0.0, 0.25)
	Ui.rise_in(_center, 34.0, 0.32)
	# The stars land one at a time once the card is up.
	_stars.filled = 0
	var count := create_tween()
	count.tween_interval(0.3)
	for star in int(outcome.stars):
		count.tween_callback(_light_star.bind(star + 1))
		count.tween_interval(0.16)
	(_next if has_next else _retry).grab_focus()


func _light_star(count: int) -> void:
	_stars.filled = count
	Audio.play(&"pickup", -6.0, 0.0, 0.9 + 0.2 * count)
