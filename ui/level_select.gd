extends Control
## The level grid: one card per level, with its stars and best time, a page of
## twelve at a time.
##
## Cards are built from [LevelCatalog], so adding a level adds a card, and a
## thirteenth level adds a page.

const COLUMNS := 4
const CARD_SIZE := Vector2(244.0, 118.0)

var _page: int = 0
var _grid: GridContainer
var _page_title: Label
var _previous: Button
var _next: Button
var _back: Button


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
	_page_title = Ui.label("", &"HeadingLabel", HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(_page_title)
	box.add_child(Ui.gap(8))

	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override(&"h_separation", 14)
	_grid.add_theme_constant_override(&"v_separation", 14)
	box.add_child(_grid)

	box.add_child(Ui.gap(14))
	var footer := Ui.row(14)
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	_previous = Ui.button("Previous", 200.0)
	_back = Ui.button("Back", 200.0)
	_next = Ui.button("Next", 200.0)
	_previous.pressed.connect(_turn_page.bind(-1))
	_next.pressed.connect(_turn_page.bind(1))
	_back.pressed.connect(SceneManager.goto_main_menu)
	footer.add_child(_previous)
	footer.add_child(_back)
	footer.add_child(_next)
	box.add_child(footer)
	box.add_child(Ui.gap(2))
	box.add_child(Ui.label("Q  E     CHANGE PAGE", &"ChipLabel", HORIZONTAL_ALIGNMENT_CENTER))

	# Open on the page the player is up to.
	_show_page(LevelCatalog.page_of(GameState.next_unbeaten()))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		SceneManager.goto_main_menu()
	elif event.is_action_pressed(&"camera_left") or event.is_action_pressed(&"ui_page_up"):
		_turn_page(-1)
	elif event.is_action_pressed(&"camera_right") or event.is_action_pressed(&"ui_page_down"):
		_turn_page(1)
	else:
		return
	get_viewport().set_input_as_handled()


func _turn_page(step: int) -> void:
	var page := clampi(_page + step, 0, LevelCatalog.page_count() - 1)
	if page == _page:
		return
	Audio.play(&"jump", -14.0, 0.04)
	_show_page(page)


func _show_page(page: int) -> void:
	_page = page
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	var first := page * LevelCatalog.PAGE_SIZE
	var focus: Button = null
	for slot in LevelCatalog.PAGE_SIZE:
		var index := first + slot
		if index >= LevelCatalog.count():
			# An empty cell the size of a card, so a short page is the same
			# size as a full one and nothing below the grid moves.
			var blank := Control.new()
			blank.custom_minimum_size = CARD_SIZE
			_grid.add_child(blank)
			continue
		var card := _build_card(index)
		_grid.add_child(card)
		# Focus lands on the level the player is up to, else the first open one.
		if not card.disabled and (focus == null or index == GameState.next_unbeaten()):
			focus = card
	_page_title.text = "%s   %d / %d" % [
		LevelCatalog.page_title(page), page + 1, LevelCatalog.page_count()]
	_previous.disabled = page <= 0
	_next.disabled = page >= LevelCatalog.page_count() - 1
	(focus if focus != null else _back).grab_focus()


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
	return card
