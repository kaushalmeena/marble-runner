class_name Hud
extends Control
## In-level HUD: a thin row along the top (gems, the clock, the level) and
## nothing else unless there is something to say. Running power-ups show as
## bars bottom left; tips fade in and out along the bottom.
##
## The HUD is read-only. It is told what to show by [code]game.gd[/code] and
## never reaches into the game to find out.
##
## Every readout has a fixed footprint. Text changing width, or something
## fading in, never moves anything else on screen. The one list that reflows
## is the running power-ups, and only when one starts or ends.

const TIP_SECONDS := 4.5
const EFFECT_KINDS: Array[PowerUps.Kind] = [
	PowerUps.Kind.SUPER_JUMP, PowerUps.Kind.BOOST, PowerUps.Kind.PLANE,
	PowerUps.Kind.MAGNET, PowerUps.Kind.STOPWATCH, PowerUps.Kind.SHIELD,
	PowerUps.Kind.DOUBLE_JUMP, PowerUps.Kind.GRIP, PowerUps.Kind.FLARE,
	PowerUps.Kind.SLOW, PowerUps.Kind.DIZZY, PowerUps.Kind.HEAVY]
const COMPLETE_COLOR := Color(1.0, 0.79, 0.24)
const FROZEN_COLOR := Color(0.78, 0.6, 1.0)

var _gems_value: Label
var _secret: Icon
var _keys_pill: PanelContainer
var _keys_value: Label
var _clock: ClockLabel
var _best: Label
var _environment_pill: PanelContainer
var _environment: Label
var _tip_panel: PanelContainer
var _tip: Label
var _banner: Label
var _flash: ColorRect
var _underwater: ColorRect
var _is_underwater: bool = false
var _effect_rows: Dictionary[int, Control] = {}
var _effect_bars: Dictionary[int, ProgressBar] = {}
var _tip_tween: Tween
var _banner_tween: Tween


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_gems()
	_build_clock()
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
	# Under the level name: what is unusual about this level's world.
	_environment_pill = PanelContainer.new()
	_environment_pill.theme_type_variation = &"HudPill"
	_environment_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_environment_pill.modulate.a = 0.0
	_environment = Ui.label("", &"ChipLabel", HORIZONTAL_ALIGNMENT_RIGHT)
	_environment.modulate = Color(0.75, 0.9, 1.0)
	_environment_pill.add_child(_environment)
	add_child(_environment_pill)
	Ui.pin(_environment_pill, Control.PRESET_TOP_RIGHT, Vector2(20, 50))


func set_gems(collected: int, total: int) -> void:
	_gems_value.text = "%d / %d" % [collected, total]
	_gems_value.modulate = COMPLETE_COLOR if collected >= total else Color.WHITE


## Replaces the target under the clock with a warning that this run will not
## be recorded.
func mark_cheated() -> void:
	_best.text = "CHEATS ON   NOT RECORDED"
	_best.modulate = Color(1.0, 0.55, 0.45)


## Lights the secret diamond's mark once the diamond is held.
func set_secret(found: bool) -> void:
	_secret.modulate.a = 1.0 if found else 0.22


## Shows how many keys are carried. The pill is hidden at zero.
func set_keys(count: int) -> void:
	_keys_value.text = str(count)
	_keys_pill.modulate.a = 1.0 if count > 0 else 0.0


func set_time(seconds: float, frozen: bool) -> void:
	_clock.text = LevelDef.format_time(seconds)
	_clock.modulate = FROZEN_COLOR if frozen else Color.WHITE


## Lists the level's standing conditions (low gravity, water) under the level
## name. Passing the same list again does nothing.
func set_environment(tags: PackedStringArray) -> void:
	var text := "   ".join(tags)
	if _environment.text == text:
		return
	_environment.text = text
	_environment_pill.modulate.a = 0.0 if tags.is_empty() else 1.0


## Updates a running effect's bar. A [param fraction] of zero hides it.
func set_effect(kind: PowerUps.Kind, fraction: float) -> void:
	if not _effect_rows.has(kind):
		return
	# Rows that are not running are taken out, so what is running sits in one
	# tight block in the corner instead of scattered across seven fixed slots.
	_effect_rows[kind].visible = fraction > 0.0
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


## Tints the whole view blue while the marble is under water. With the water
## drawn only as a surface, this is what says "you are in it".
func set_underwater(under: bool) -> void:
	if under == _is_underwater:
		return
	_is_underwater = under
	create_tween().tween_property(_underwater, ^"color:a", 0.24 if under else 0.0, 0.2)


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
	# The level's secret diamond: a faint outline until it is in hand. It has its
	# place in the pill from the start, so finding it moves nothing.
	_secret = Icon.new(Icon.Kind.DIAMOND, 22.0, Icon.DIAMOND_WHITE)
	_secret.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_secret.modulate.a = 0.22
	box.add_child(_secret)
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


func _build_effects() -> void:
	var box := Ui.column(5)
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
		entry.visible = false
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
	Ui.pin(_tip_panel, Control.PRESET_CENTER_BOTTOM, Vector2(0, 26))


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
	_underwater = ColorRect.new()
	_underwater.color = Color(WaterZone.COLOR, 0.0)
	_underwater.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_underwater.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_underwater)
	move_child(_underwater, 0)
	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_flash)
