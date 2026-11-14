extends Control
## Skin shop: one marble on show, and a row of swatches to pick from.
##
## The big preview is a live 3D marble, because these are veined materials
## whose character is in the surface and a flat swatch cannot show that. The
## swatches underneath are for finding your way around: what there is, what is
## owned, what is on. Browsing is free; only buying and equipping touch
## [GameState].

const PREVIEW := preload("res://ui/marble_preview.tscn")
const AFFORDABLE := Color(1.0, 0.82, 0.25)
const TOO_DEAR := Color(1.0, 0.5, 0.5)

var _skins: Array[MarbleSkin] = []
var _chips: Array[SkinChip] = []
var _index: int = 0
var _preview: MarblePreview
var _name_label: Label
var _description: Label
var _status: Label
var _status_coin: Icon
var _coins: StatPill
var _action: Button
var _swap_tween: Tween


func _ready() -> void:
	_skins.assign(SkinLibrary.load_default().skins.filter(
		func(skin: MarbleSkin) -> bool: return skin != null))
	add_child(Ui.shade(Color(0.03, 0.06, 0.12, 0.7)))

	var title := Ui.column(-6)
	title.add_child(Ui.label("MARBLES", &"CaptionLabel"))
	title.add_child(Ui.label("SHOP", &"HeadingLabel"))
	add_child(title)
	Ui.pin(title, Control.PRESET_TOP_LEFT, Vector2(32, 16))
	_coins = StatPill.new(Icon.Kind.COIN, Icon.GOLD)
	add_child(_coins)
	Ui.pin(_coins, Control.PRESET_TOP_RIGHT, Vector2(24, 20))

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := Ui.column(14)
	center.add_child(box)

	var stage := Ui.row(22)
	stage.alignment = BoxContainer.ALIGNMENT_CENTER
	var previous := Ui.round_button(Icon.Kind.LEFT)
	var next := Ui.round_button(Icon.Kind.RIGHT)
	previous.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	next.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	previous.focus_mode = Control.FOCUS_NONE
	next.focus_mode = Control.FOCUS_NONE
	previous.pressed.connect(_step.bind(-1))
	next.pressed.connect(_step.bind(1))
	stage.add_child(previous)
	stage.add_child(_build_card())
	stage.add_child(next)
	box.add_child(stage)

	var swatches := Ui.row(10)
	swatches.alignment = BoxContainer.ALIGNMENT_CENTER
	for index in _skins.size():
		var chip := SkinChip.new(_skins[index].accent_color)
		chip.pressed.connect(_show.bind(index))
		swatches.add_child(chip)
		_chips.append(chip)
	box.add_child(swatches)

	var buttons := Ui.row(14)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	var back := Ui.button("Back", 200.0, Icon.Kind.BACK)
	back.pressed.connect(SceneManager.goto_main_menu)
	_action = Ui.button("Equip", 260.0, Icon.Kind.NONE, &"PrimaryButton")
	_action.pressed.connect(_on_action_pressed)
	buttons.add_child(back)
	buttons.add_child(_action)
	box.add_child(buttons)

	var keys := Ui.key_hint(["A", "D"], "BROWSE")
	add_child(keys)
	Ui.pin(keys, Control.PRESET_CENTER_BOTTOM, Vector2(0, 16))

	GameState.coins_changed.connect(_on_coins_changed)
	_on_coins_changed(GameState.coins)
	# Open on whatever the player is currently wearing.
	_index = maxi(0, _skins.find(_current_equipped()))
	_refresh()
	Ui.cascade(_chips, 0.1, 0.03)
	_action.grab_focus()


func _build_card() -> PanelContainer:
	var card := PanelContainer.new()
	var box := Ui.column(0)
	box.custom_minimum_size.x = 440.0
	card.add_child(box)
	_preview = PREVIEW.instantiate()
	_preview.custom_minimum_size = Vector2(250.0, 230.0)
	_preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(_preview)
	_name_label = Ui.label("", &"HeadingLabel", HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(_name_label)
	_description = Ui.label("", &"HintLabel", HORIZONTAL_ALIGNMENT_CENTER)
	_description.modulate.a = 0.85
	box.add_child(_description)
	box.add_child(Ui.gap(8))
	# The coin is hidden, not removed, once a skin is owned: the line keeps its
	# height either way.
	var status := Ui.row(8)
	status.alignment = BoxContainer.ALIGNMENT_CENTER
	status.custom_minimum_size.y = 34.0
	_status_coin = Icon.new(Icon.Kind.COIN, 22.0, Icon.GOLD)
	_status_coin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	status.add_child(_status_coin)
	_status = Ui.label("", &"AccentLabel")
	status.add_child(_status)
	box.add_child(status)
	return card


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"move_left"):
		_step(-1)
	elif event.is_action_pressed(&"move_right"):
		_step(1)
	elif event.is_action_pressed(&"ui_cancel"):
		SceneManager.goto_main_menu()
	else:
		return
	get_viewport().set_input_as_handled()


func _step(direction: int) -> void:
	if not _skins.is_empty():
		_show(wrapi(_index + direction, 0, _skins.size()))


func _show(index: int) -> void:
	if index == _index:
		return
	_index = index
	Audio.play(&"jump", -14.0, 0.04)
	_refresh()
	# The marble blinks out and back as it changes, so a swap reads as a swap.
	if _swap_tween != null:
		_swap_tween.kill()
	_preview.modulate.a = 0.0
	_swap_tween = create_tween()
	_swap_tween.tween_property(_preview, ^"modulate:a", 1.0, 0.22)


## Redraws everything that depends on which skin is on show and what the
## player owns. The action button is the only control whose meaning changes:
## buy what you can afford, equip what you own, nothing when it is already on.
func _refresh() -> void:
	if _skins.is_empty():
		return
	var skin := _skins[_index]
	var owned := GameState.is_skin_unlocked(skin)
	var equipped := owned and GameState.selected_skin == skin.id
	_preview.show_skin(skin)
	_name_label.text = skin.display_name
	_description.text = skin.description
	_status_coin.visible = not owned
	if equipped:
		_status.text = "EQUIPPED"
		_status.add_theme_color_override(&"font_color", skin.accent_color.lightened(0.25))
		_action.text = "Equipped"
	elif owned:
		_status.text = "OWNED"
		_status.add_theme_color_override(&"font_color", Color(1, 1, 1, 0.8))
		_action.text = "Equip"
	else:
		var affordable := GameState.coins >= skin.price
		_status.text = str(skin.price)
		_status.add_theme_color_override(&"font_color", AFFORDABLE if affordable else TOO_DEAR)
		_action.text = "Buy" if affordable else "Not enough coins"
	_action.disabled = equipped or (not owned and GameState.coins < skin.price)
	for index in _chips.size():
		var other := _skins[index]
		var has := GameState.is_skin_unlocked(other)
		_chips[index].current = index == _index
		_chips[index].state = SkinChip.State.LOCKED if not has else (
			SkinChip.State.EQUIPPED if GameState.selected_skin == other.id
			else SkinChip.State.OWNED)


func _on_action_pressed() -> void:
	var skin := _skins[_index]
	if GameState.is_skin_unlocked(skin):
		if GameState.select_skin(skin):
			Audio.play(&"pickup")
	elif GameState.purchase_skin(skin):
		Audio.play(&"power_up")
		# Nobody buys a marble to leave it in the drawer.
		GameState.select_skin(skin)
	_refresh()


func _on_coins_changed(coins: int) -> void:
	_coins.text = str(coins)
	_refresh()


func _current_equipped() -> MarbleSkin:
	for skin in _skins:
		if skin.id == GameState.selected_skin:
			return skin
	return null
