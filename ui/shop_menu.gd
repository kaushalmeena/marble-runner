extends Control
## Skin shop. Buy with coins, equip what you own.
##
## Cards are built from the library rather than authored one by one, so adding
## a skin needs no change here.

@onready var _grid: GridContainer = %Grid
@onready var _coins_value: Label = %CoinsValue
@onready var _back_button: Button = %BackButton

var _cards: Array[SkinCard] = []


func _ready() -> void:
	_back_button.pressed.connect(SceneManager.goto_main_menu)
	GameState.coins_changed.connect(_on_coins_changed)
	_on_coins_changed(GameState.coins)

	var card_scene: PackedScene = load("res://ui/skin_card.tscn")
	for skin in SkinLibrary.load_default().skins:
		if skin == null:
			continue
		var card: SkinCard = card_scene.instantiate()
		_grid.add_child(card)
		card.setup(skin)
		card.buy_requested.connect(_on_buy_requested)
		card.equip_requested.connect(_on_equip_requested)
		_cards.append(card)

	_back_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		SceneManager.goto_main_menu()


func _on_buy_requested(skin: MarbleSkin) -> void:
	if not GameState.purchase_skin(skin):
		return
	Audio.play(&"power_up")
	# Equip straight away: nobody buys a skin to leave it in the drawer.
	GameState.select_skin(skin)
	_refresh_all()


func _on_equip_requested(skin: MarbleSkin) -> void:
	if GameState.select_skin(skin):
		Audio.play(&"pickup")
		_refresh_all()


func _on_coins_changed(coins: int) -> void:
	_coins_value.text = str(coins)
	# A purchase can make other skins unaffordable, so every card re-reads.
	_refresh_all()


func _refresh_all() -> void:
	for card in _cards:
		card.refresh()
