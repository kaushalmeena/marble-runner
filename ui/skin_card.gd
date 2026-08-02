class_name SkinCard
extends PanelContainer
## One skin in the shop: swatch, name, and a button that means buy, equip or
## nothing depending on what the player owns.

## The player pressed the button while the skin was affordable but unowned.
signal buy_requested(skin: MarbleSkin)
## The player pressed the button on a skin they already own.
signal equip_requested(skin: MarbleSkin)

@onready var _swatch: Panel = %Swatch
@onready var _name_label: Label = %NameLabel
@onready var _status: Label = %Status
@onready var _button: Button = %ActionButton

var _skin: MarbleSkin = null


func _ready() -> void:
	_button.pressed.connect(_on_button_pressed)


## Fills the card in and colours the swatch to match the skin.
func setup(skin: MarbleSkin) -> void:
	_skin = skin
	_name_label.text = skin.display_name
	# Flavour lives in the tooltip so the grid stays compact.
	tooltip_text = skin.description
	var style := StyleBoxFlat.new()
	style.bg_color = skin.accent_color
	style.corner_radius_top_left = 40
	style.corner_radius_top_right = 40
	style.corner_radius_bottom_right = 40
	style.corner_radius_bottom_left = 40
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color(1, 1, 1, 0.35)
	_swatch.add_theme_stylebox_override(&"panel", style)
	refresh()


## Re-reads ownership and coins. Called on every card whenever either changes,
## because buying one skin can make another unaffordable.
func refresh() -> void:
	if _skin == null:
		return
	var owned := GameState.is_skin_unlocked(_skin)
	var equipped := owned and GameState.selected_skin == _skin.id

	if equipped:
		_status.text = "EQUIPPED"
		_button.text = "Equipped"
		_button.disabled = true
	elif owned:
		_status.text = "OWNED"
		_button.text = "Equip"
		_button.disabled = false
	else:
		_status.text = "%d COINS" % _skin.price
		_button.text = "Buy"
		_button.disabled = GameState.coins < _skin.price

	_status.add_theme_color_override(&"font_color",
		_skin.accent_color if equipped else Color(1, 1, 1, 0.7))


func _on_button_pressed() -> void:
	if GameState.is_skin_unlocked(_skin):
		equip_requested.emit(_skin)
	else:
		buy_requested.emit(_skin)
