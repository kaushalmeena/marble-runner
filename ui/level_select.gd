extends Control
## The level grid: one card per level, a course of twelve at a time.
##
## Cards are built from [LevelCatalog], so adding a level adds a card, and a
## thirteenth level adds a page. The page last looked at is remembered in
## [GameState], so coming back from a level reopens the course it is on.

const COLUMNS := 4
const CARD_SIZE := Vector2(232.0, 118.0)
const GRID_GAP := 12.0
const LOCKED_TINT := Color(0.45, 0.5, 0.6)
## How far the grid slides when the page turns.
const TURN_DISTANCE := 60.0

var _page: int = -1
var _grid: GridContainer
var _stage: Control
var _kicker: Label
var _page_title: Label
var _dots: PageDots
var _course_stars: StatPill
var _previous: Button
var _next: Button
var _back: Button
var _turn_tween: Tween


func _ready() -> void:
	add_child(Ui.shade(Color(0.03, 0.06, 0.12, 0.66)))
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := Ui.column(0)
	center.add_child(box)

	_kicker = Ui.label("", &"CaptionLabel", HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(_kicker)
	_page_title = Ui.label("", &"HeadingLabel", HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(_page_title)
	_dots = PageDots.new()
	_dots.count = LevelCatalog.page_count()
	box.add_child(_dots)
	box.add_child(Ui.gap(18))

	var rows := ceili(float(LevelCatalog.PAGE_SIZE) / COLUMNS)
	var grid_size := Vector2(
		COLUMNS * CARD_SIZE.x + (COLUMNS - 1) * GRID_GAP,
		rows * CARD_SIZE.y + (rows - 1) * GRID_GAP)
	var middle := Ui.row(16)
	_previous = Ui.round_button(Icon.Kind.LEFT)
	_next = Ui.round_button(Icon.Kind.RIGHT)
	_previous.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_next.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_previous.pressed.connect(_turn_page.bind(-1))
	_next.pressed.connect(_turn_page.bind(1))
	# The grid sits in a plain control of fixed size rather than straight in
	# the row, so it can slide when the page turns without a container
	# snapping it back.
	_stage = Control.new()
	_stage.custom_minimum_size = grid_size
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override(&"h_separation", int(GRID_GAP))
	_grid.add_theme_constant_override(&"v_separation", int(GRID_GAP))
	_stage.add_child(_grid)
	middle.add_child(_previous)
	middle.add_child(_stage)
	middle.add_child(_next)
	box.add_child(middle)

	box.add_child(Ui.gap(18))
	var footer := Ui.row(18)
	footer.custom_minimum_size.x = grid_size.x
	footer.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_back = Ui.button("Back", 190.0, Icon.Kind.BACK)
	_back.pressed.connect(SceneManager.goto_main_menu)
	footer.add_child(_back)
	footer.add_child(Ui.spring())
	var hint := Ui.key_hint(["Q", "E"], "CHANGE COURSE")
	hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	footer.add_child(hint)
	footer.add_child(Ui.spring())
	_course_stars = StatPill.new(Icon.Kind.STAR, Icon.GOLD)
	_course_stars.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	footer.add_child(_course_stars)
	box.add_child(footer)

	# Open where it was left; the first time, on the page the player is up to.
	var page := GameState.level_page
	if page < 0 or page >= LevelCatalog.page_count():
		page = LevelCatalog.page_of(GameState.next_unbeaten())
	_show_page(page, 0)


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
	_show_page(page, step)
	GameState.level_page = page
	GameState.save_progress()


## Fills the grid with [param page]. [param direction] is which way the page
## turned, and so which side the new cards slide in from; zero is the first
## showing, where they only fade.
func _show_page(page: int, direction: int) -> void:
	_page = page
	GameState.level_page = page
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	var first := page * LevelCatalog.PAGE_SIZE
	var focus: Button = null
	var cards: Array = []
	var stars := 0
	var levels := 0
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
		cards.append(card)
		levels += 1
		stars += GameState.stars(LevelCatalog.at(index))
		# Focus lands on the level the player is up to, else the first open one.
		if not card.disabled and (focus == null or index == GameState.next_unbeaten()):
			focus = card
	_kicker.text = "COURSE %d OF %d" % [page + 1, LevelCatalog.page_count()]
	_page_title.text = LevelCatalog.page_title(page)
	_dots.current = page
	_course_stars.text = "%d / %d" % [stars, levels * StarRow.COUNT]
	_previous.disabled = page <= 0
	_next.disabled = page >= LevelCatalog.page_count() - 1
	(focus if focus != null else _back).grab_focus()

	if _turn_tween != null:
		_turn_tween.kill()
	_grid.position = Vector2(direction * TURN_DISTANCE, 0.0)
	_turn_tween = create_tween()
	_turn_tween.tween_property(_grid, ^"position:x", 0.0, 0.26) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	Ui.cascade(cards, 0.0, 0.018)


func _build_card(index: int) -> Button:
	var level := LevelCatalog.at(index)
	var open := GameState.is_unlocked(index)
	var best := GameState.best_time(level)
	var card := Button.new()
	card.theme_type_variation = &"LevelCard"
	card.custom_minimum_size = CARD_SIZE
	card.disabled = not open
	card.pressed.connect(SceneManager.play_level.bind(index))

	# The badge wears the level's sky, so a course reads as a run of places.
	var badge := PanelContainer.new()
	badge.theme_type_variation = &"Badge"
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.self_modulate = level.biome.sky_top_color.lerp(level.biome.ground_color, 0.25) \
		if open else LOCKED_TINT
	badge.position = Vector2(14.0, 13.0)
	badge.size = Vector2(54.0, 53.0)
	if open:
		badge.add_child(Ui.label("%d" % (index + 1), &"BadgeLabel", HORIZONTAL_ALIGNMENT_CENTER))
	else:
		var lock := Icon.new(Icon.Kind.LOCK, 22.0)
		lock.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		lock.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		badge.add_child(lock)
	card.add_child(badge)

	var title := Ui.label(level.title, &"CardTitle")
	title.clip_text = true
	title.position = Vector2(80.0, 12.0)
	title.size = Vector2(CARD_SIZE.x - 92.0, 26.0)
	card.add_child(title)
	var conditions := level.conditions()
	var place := Ui.label(
		level.biome.biome_name.to_upper() if conditions.is_empty() else "  ".join(conditions),
		&"ChipLabel")
	place.modulate = Color(0.75, 0.88, 1.0, 0.85)
	place.clip_text = true
	place.position = Vector2(80.0, 39.0)
	place.size = Vector2(CARD_SIZE.x - 92.0, 18.0)
	card.add_child(place)

	var stars := StarRow.new(20.0, GameState.stars(level))
	stars.position = Vector2(14.0, 80.0)
	card.add_child(stars)
	var status: Control
	if open and best < 0.0 and index == GameState.next_unbeaten():
		var tag := PanelContainer.new()
		tag.theme_type_variation = &"Tag"
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tag.add_child(Ui.label("UP NEXT", &"TagLabel"))
		status = tag
	else:
		status = Ui.label("LOCKED" if not open else (
			LevelDef.format_time(best) if best >= 0.0 else "NEW"), &"CaptionLabel")
	card.add_child(status)
	Ui.pin(status, Control.PRESET_BOTTOM_RIGHT, Vector2(14.0, 17.0))
	if not open:
		for child: Control in [title, place, stars, status]:
			child.modulate.a = 0.45
	return card
