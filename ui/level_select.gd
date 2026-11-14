extends Control
## The level grid: one card per level, with its stars and best time.
##
## Cards are built from [LevelCatalog], so adding a level adds a card.

const COLUMNS := 4
const CARD_SIZE := Vector2(244.0, 118.0)

var _first_open: Button = null


func _ready() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.06, 0.12, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := Ui.column(4)
	center.add_child(box)

	box.add_child(Ui.label("%d OF %d STARS" % [
		GameState.total_stars(), LevelCatalog.count() * StarRow.COUNT],
		&"CaptionLabel", HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(Ui.label("LEVELS", &"HeadingLabel", HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(Ui.gap(8))

	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override(&"h_separation", 14)
	grid.add_theme_constant_override(&"v_separation", 14)
	box.add_child(grid)
	for index in LevelCatalog.count():
		grid.add_child(_build_card(index))

	box.add_child(Ui.gap(14))
	var back := Ui.button("Back", 240.0)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(SceneManager.goto_main_menu)
	box.add_child(back)
	(_first_open if _first_open != null else back).grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		SceneManager.goto_main_menu()


func _build_card(index: int) -> Button:
	var level := LevelCatalog.at(index)
	var open := GameState.is_unlocked(index)
	var card := Button.new()
	card.custom_minimum_size = CARD_SIZE
	card.disabled = not open
	card.pressed.connect(SceneManager.play_level.bind(index))

	var box := Ui.column(-2)
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 18.0
	box.offset_top = 10.0
	box.offset_right = -18.0
	box.offset_bottom = -10.0
	card.add_child(box)
	box.add_child(Ui.label("LEVEL %02d" % (index + 1), &"CaptionLabel"))
	var title := Ui.label(level.title, &"AccentLabel" if open else &"HintLabel")
	title.clip_text = true
	box.add_child(title)
	var footer := Ui.row(10)
	footer.size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_SHRINK_END
	footer.add_child(StarRow.new(20.0, GameState.stars(level)))
	var best := GameState.best_time(level)
	var status := "LOCKED" if not open else (
		LevelDef.format_time(best) if best >= 0.0 else "NEW")
	var time := Ui.label(status, &"CaptionLabel", HORIZONTAL_ALIGNMENT_RIGHT)
	time.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(time)
	box.add_child(footer)
	if not open:
		box.modulate.a = 0.5
	# Focus lands on the level the player is up to, not on level one.
	if open and (_first_open == null or not GameState.is_completed(level)):
		if _first_open == null or GameState.is_completed(LevelCatalog.at(index - 1)):
			_first_open = card
	return card
