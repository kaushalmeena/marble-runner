extends Control
## Skin shop, shown one marble at a time.
##
## A carousel rather than a grid: with a live 3D preview the marble can be big
## enough to actually see, which a wall of thumbnails cannot manage. Browsing is
## free; only buying and equipping touch [GameState].

@onready var _preview: MarblePreview = %Preview
@onready var _name_label: Label = %NameLabel
@onready var _description: Label = %Description
@onready var _status: Label = %Status
@onready var _position_label: Label = %PositionLabel
@onready var _coins_value: Label = %CoinsValue
@onready var _action_button: Button = %ActionButton
@onready var _prev_button: Button = %PrevButton
@onready var _next_button: Button = %NextButton
@onready var _back_button: Button = %BackButton
@onready var _doubler_button: Button = %DoublerButton
@onready var _head_start_button: Button = %HeadStartButton

var _skins: Array[MarbleSkin] = []
var _index: int = 0


func _ready() -> void:
	_skins.assign(SkinLibrary.load_default().skins.filter(
		func(skin: MarbleSkin) -> bool: return skin != null))

	_prev_button.pressed.connect(_step.bind(-1))
	_next_button.pressed.connect(_step.bind(1))
	_action_button.pressed.connect(_on_action_pressed)
	_back_button.pressed.connect(SceneManager.goto_main_menu)
	_doubler_button.pressed.connect(_buy_boost.bind(GameState.BOOST_DOUBLER))
	_head_start_button.pressed.connect(_buy_boost.bind(GameState.BOOST_HEAD_START))
	GameState.coins_changed.connect(_on_coins_changed)

	# Open on whatever the player is currently wearing.
	_index = maxi(0, _skins.find(_current_equipped()))
	_on_coins_changed(GameState.coins)
	_show_current()
	_action_button.grab_focus()


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
	if _skins.is_empty():
		return
	_index = wrapi(_index + direction, 0, _skins.size())
	Audio.play(&"jump", -14.0, 0.04)
	_show_current()


func _show_current() -> void:
	var skin := _skins[_index]
	_preview.show_skin(skin)
	_name_label.text = skin.display_name
	_description.text = skin.description
	_position_label.text = "%d / %d" % [_index + 1, _skins.size()]
	_refresh_action()


## The button is the only control whose meaning changes: buy what you can
## afford, equip what you own, and nothing when it is already on.
func _refresh_action() -> void:
	if _skins.is_empty():
		return
	var skin := _skins[_index]
	var owned := GameState.is_skin_unlocked(skin)
	var equipped := owned and GameState.selected_skin == skin.id

	if equipped:
		_status.text = "EQUIPPED"
		_status.add_theme_color_override(&"font_color", skin.accent_color)
		_action_button.text = "Equipped"
		_action_button.disabled = true
	elif owned:
		_status.text = "OWNED"
		_status.add_theme_color_override(&"font_color", Color(1, 1, 1, 0.75))
		_action_button.text = "Equip"
		_action_button.disabled = false
	else:
		_status.text = "%d COINS" % skin.price
		var affordable := GameState.coins >= skin.price
		_status.add_theme_color_override(&"font_color",
			Color(1, 0.82, 0.25) if affordable else Color(1, 0.45, 0.45))
		_action_button.text = "Buy"
		_action_button.disabled = not affordable


func _on_action_pressed() -> void:
	var skin := _skins[_index]
	if GameState.is_skin_unlocked(skin):
		if GameState.select_skin(skin):
			Audio.play(&"pickup")
	elif GameState.purchase_skin(skin):
		Audio.play(&"power_up")
		# Nobody buys a marble to leave it in the drawer.
		GameState.select_skin(skin)
	_refresh_action()


func _on_coins_changed(coins: int) -> void:
	_coins_value.text = str(coins)
	_refresh_action()
	_refresh_boosts()


func _buy_boost(id: StringName) -> void:
	if GameState.purchase_boost(id):
		Audio.play(&"power_up")
	_refresh_boosts()


## Boosts stack, so the label carries the count rather than an owned/not state.
func _refresh_boosts() -> void:
	_show_boost(_doubler_button, GameState.BOOST_DOUBLER, "Coin Doubler")
	_show_boost(_head_start_button, GameState.BOOST_HEAD_START, "Head Start")


func _show_boost(button: Button, id: StringName, label: String) -> void:
	var owned := GameState.boost_count(id)
	var price := GameState.boost_price(id)
	var suffix := "  x%d" % owned if owned > 0 else ""
	button.text = "%s  ·  %d%s" % [label, price, suffix]
	button.disabled = GameState.coins < price


func _current_equipped() -> MarbleSkin:
	for skin in _skins:
		if skin.id == GameState.selected_skin:
			return skin
	return null
