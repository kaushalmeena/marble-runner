class_name Hud
extends Control
## In-level HUD: a thin row along the top (gems, the clock, the level) and
## nothing else unless there is something to say. The power-up pill only exists
## while a power-up is held; tips and effect bars fade in and out.
##
## The HUD is read-only. It is told what to show by [code]game.gd[/code] and
## never reaches into the game to find out.
##
## Every readout has a fixed footprint. Text changing width, or something
## fading in, never moves anything else on screen.

const TIP_SECONDS := 4.5
const EFFECT_KINDS: Array[PowerUps.Kind] = [
	PowerUps.Kind.FEATHER, PowerUps.Kind.MAGNET, PowerUps.Kind.STOPWATCH,
	PowerUps.Kind.SHIELD, PowerUps.Kind.DOUBLE_JUMP]
const COMPLETE_COLOR := Color(1.0, 0.79, 0.24)
const FROZEN_COLOR := Color(0.78, 0.6, 1.0)

var _gems_value: Label
var _keys_pill: PanelContainer
var _keys_value: Label
var _clock: ClockLabel
var _best: Label
var _slot: PanelContainer
var _slot_name: Label
var _slot_tween: Tween
var _tip_panel: PanelContainer
var _tip: Label
var _banner: Label
var _flash: ColorRect
var _effect_rows: Dictionary[int, Control] = {}
var _effect_bars: Dictionary[int, ProgressBar] = {}
var _tip_tween: Tween
var _banner_tween: Tween


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_gems()
	_build_clock()
	_build_slot()
	_build_effects()
	_build_tip()
	_build_banner()


## Fills in everything that is fixed for the level.
func setup(level_number: int, level: LevelDef, gem_total: int, best_time: float) -> void:
	set_gems(0, gem_total)
	set_time(0.0, false)
	_best.text = "BEST  %s" % LevelDef.format_time(best_time) if best_time >= 0.0 \
		else "GOLD  %s" % LevelDef.format_time(level.gold_time)
	var title := Ui.label("LEVEL %02d   %s" % [level_number, level.title.to_upper()],
		&"CaptionLabel", HORIZONTAL_ALIGNMENT_RIGHT)
	add_child(title)
	Ui.pin(title, Control.PRESET_TOP_RIGHT, Vector2(24, 20))
	set_power_up(-1)


func set_gems(collected: int, total: int) -> void:
	_gems_value.text = "%d / %d" % [collected, total]
	_gems_value.modulate = COMPLETE_COLOR if collected >= total else Color.WHITE


## Shows how many keys are carried. The pill is hidden at zero.
func set_keys(count: int) -> void:
	_keys_value.text = str(count)
	_keys_pill.modulate.a = 1.0 if count > 0 else 0.0


func set_time(seconds: float, frozen: bool) -> void:
	_clock.text = LevelDef.format_time(seconds)
	_clock.modulate = FROZEN_COLOR if frozen else Color.WHITE


## Shows what is in the slot. Pass a negative [param kind] for empty, which
## hides the pill altogether: an empty slot is not worth screen space.
func set_power_up(kind: int) -> void:
	if _slot_tween != null:
		_slot_tween.kill()
	_slot_tween = create_tween()
	if kind < 0:
		_slot_tween.tween_property(_slot, ^"modulate:a", 0.0, 0.15)
		return
	_slot_name.text = PowerUps.label(kind)
	_slot_name.modulate = PowerUps.color(kind).lightened(0.25)
	_slot.pivot_offset = _slot.size / 2.0
	_slot.scale = Vector2.ONE * 1.2
	_slot_tween.set_parallel()
	_slot_tween.tween_property(_slot, ^"modulate:a", 1.0, 0.12)
	_slot_tween.tween_property(_slot, ^"scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Updates a running effect's bar. A [param fraction] of zero hides it.
func set_effect(kind: PowerUps.Kind, fraction: float) -> void:
	if not _effect_rows.has(kind):
		return
	# Faded rather than hidden: a hidden row would shuffle the ones below it.
	_effect_rows[kind].modulate.a = 1.0 if fraction > 0.0 else 0.0
	_effect_bars[kind].value = fraction


## Shows a line of guidance at the bottom of the screen for a few seconds.
func show_tip(text: String) -> void:
	_tip.text = text
	if _tip_tween != null:
		_tip_tween.kill()
	_tip_tween = create_tween()
	_tip_tween.tween_property(_tip_panel, ^"modulate:a", 1.0, 0.2)
	_tip_tween.tween_interval(TIP_SECONDS)
	_tip_tween.tween_property(_tip_panel, ^"modulate:a", 0.0, 0.5)


## Shows a large word in the middle of the screen, briefly.
func show_banner(text: String, seconds: float = 0.8, color := Color.WHITE) -> void:
	_banner.text = text
	_banner.modulate = color
	_banner.pivot_offset = _banner.size / 2.0
	_banner.scale = Vector2.ONE * 1.15
	if _banner_tween != null:
		_banner_tween.kill()
	_banner_tween = create_tween()
	_banner_tween.tween_property(_banner, ^"scale", Vector2.ONE, 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_banner_tween.tween_interval(seconds)
	_banner_tween.tween_property(_banner, ^"modulate:a", 0.0, 0.25)


## A brief wash of colour over the whole view, for falls and the finish.
func flash(color: Color) -> void:
	_flash.color = color
	var tween := create_tween()
	tween.tween_property(_flash, ^"color:a", 0.0, 0.45)


func _build_gems() -> void:
	var pill := PanelContainer.new()
	pill.theme_type_variation = &"HudPill"
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := Ui.row(10)
	var caption := Ui.label("GEMS", &"CaptionLabel")
	caption.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(caption)
	_gems_value = Ui.label("0 / 0", &"AccentLabel", HORIZONTAL_ALIGNMENT_RIGHT)
	_gems_value.add_theme_color_override(&"font_color", Color.WHITE)
	_gems_value.custom_minimum_size.x = 78.0
	box.add_child(_gems_value)
	pill.add_child(box)
	add_child(pill)
	Ui.pin(pill, Control.PRESET_TOP_LEFT, Vector2(20, 14))

	_keys_pill = PanelContainer.new()
	_keys_pill.theme_type_variation = &"HudPill"
	_keys_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_keys_pill.modulate.a = 0.0
	var keys := Ui.row(10)
	var keys_caption := Ui.label("KEYS", &"CaptionLabel")
	keys_caption.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	keys.add_child(keys_caption)
	_keys_value = Ui.label("0", &"AccentLabel", HORIZONTAL_ALIGNMENT_RIGHT)
	_keys_value.custom_minimum_size.x = 24.0
	keys.add_child(_keys_value)
	_keys_pill.add_child(keys)
	add_child(_keys_pill)
	Ui.pin(_keys_pill, Control.PRESET_TOP_LEFT, Vector2(20, 60))


func _build_clock() -> void:
	var box := Ui.column(-5)
	_clock = ClockLabel.new(&"TimerLabel")
	_clock.custom_minimum_size.x = 220.0
	box.add_child(_clock)
	_best = Ui.label("", &"ChipLabel", HORIZONTAL_ALIGNMENT_CENTER)
	_best.add_theme_constant_override(&"outline_size", 4)
	box.add_child(_best)
	add_child(box)
	Ui.pin(box, Control.PRESET_CENTER_TOP, Vector2(0, 6))


func _build_slot() -> void:
	_slot = PanelContainer.new()
	_slot.theme_type_variation = &"HudPill"
	_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_slot.modulate.a = 0.0
	var box := Ui.row(12)
	var key := Ui.label("SHIFT", &"CaptionLabel")
	key.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(key)
	_slot_name = Ui.label("", &"AccentLabel", HORIZONTAL_ALIGNMENT_CENTER)
	_slot_name.add_theme_color_override(&"font_color", Color.WHITE)
	_slot_name.custom_minimum_size.x = 150.0
	box.add_child(_slot_name)
	_slot.add_child(box)
	add_child(_slot)
	Ui.pin(_slot, Control.PRESET_CENTER_BOTTOM, Vector2(0, 22))


func _build_effects() -> void:
	var box := Ui.column(8)
	for kind in EFFECT_KINDS:
		var entry := Ui.column(2)
		entry.add_child(Ui.label(PowerUps.label(kind), &"ChipLabel"))
		var bar := ProgressBar.new()
		bar.max_value = 1.0
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(150.0, 7.0)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.modulate = PowerUps.color(kind)
		entry.add_child(bar)
		entry.modulate.a = 0.0
		box.add_child(entry)
		_effect_rows[kind] = entry
		_effect_bars[kind] = bar
	add_child(box)
	Ui.pin(box, Control.PRESET_BOTTOM_LEFT, Vector2(22, 20))


func _build_tip() -> void:
	_tip_panel = PanelContainer.new()
	_tip_panel.theme_type_variation = &"HudPill"
	_tip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip_panel.modulate.a = 0.0
	_tip = Ui.label("", &"HintLabel", HORIZONTAL_ALIGNMENT_CENTER)
	_tip_panel.add_child(_tip)
	add_child(_tip_panel)
	Ui.pin(_tip_panel, Control.PRESET_CENTER_BOTTOM, Vector2(0, 76))


func _build_banner() -> void:
	# Full width and centred by alignment, not by growing from a point: a
	# label that grows from its centre is briefly mis-sized when its text
	# changes, which put short banners half off the screen.
	_banner = Ui.label("", &"TitleLabel", HORIZONTAL_ALIGNMENT_CENTER)
	_banner.modulate.a = 0.0
	_banner.anchor_left = 0.0
	_banner.anchor_right = 1.0
	_banner.anchor_top = 0.3
	_banner.anchor_bottom = 0.3
	_banner.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(_banner)
	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_flash)
