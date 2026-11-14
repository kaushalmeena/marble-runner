extends Control
## Title screen.

@onready var _play_button: Button = %PlayButton
@onready var _levels_button: Button = %LevelsButton
@onready var _shop_button: Button = %ShopButton
@onready var _settings_button: Button = %SettingsButton
@onready var _quit_button: Button = %QuitButton
@onready var _coins_value: Label = %CoinsValue
@onready var _stars_value: Label = %StarsValue


func _ready() -> void:
	_coins_value.text = str(GameState.coins)
	_stars_value.text = "%d / %d STARS" % [
		GameState.total_stars(), LevelCatalog.count() * StarRow.COUNT]
	# "Play" always means the next thing worth playing; "Levels" is for choosing.
	var next := GameState.next_unbeaten()
	_play_button.text = "Play" if next == 0 else "Continue  -  Level %d" % (next + 1)
	_play_button.pressed.connect(SceneManager.continue_game)
	_levels_button.pressed.connect(SceneManager.goto_level_select)
	_shop_button.pressed.connect(SceneManager.goto_shop)
	_settings_button.pressed.connect(SceneManager.goto_settings)
	_quit_button.pressed.connect(SceneManager.quit_game)
	# A browser tab cannot be quit from inside the page.
	_quit_button.visible = not OS.has_feature("web")
	# Makes the menu playable with the keyboard alone.
	_play_button.grab_focus()
