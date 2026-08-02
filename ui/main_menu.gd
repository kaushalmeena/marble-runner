extends Control
## Title screen.

@onready var _play_button: Button = %PlayButton
@onready var _shop_button: Button = %ShopButton
@onready var _settings_button: Button = %SettingsButton
@onready var _quit_button: Button = %QuitButton
@onready var _coins_value: Label = %CoinsValue


func _ready() -> void:
	_coins_value.text = str(GameState.coins)
	_play_button.pressed.connect(SceneManager.start_game)
	_shop_button.pressed.connect(SceneManager.goto_shop)
	_settings_button.pressed.connect(SceneManager.goto_settings)
	_quit_button.pressed.connect(SceneManager.quit_game)
	# Makes the menu playable with the keyboard alone.
	_play_button.grab_focus()
