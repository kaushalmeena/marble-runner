extends Control
## Title screen.

@onready var _best_value: Label = %BestValue
@onready var _play_button: Button = %PlayButton
@onready var _quit_button: Button = %QuitButton


func _ready() -> void:
	_best_value.text = str(GameState.best_score)
	_play_button.pressed.connect(SceneManager.start_game)
	_quit_button.pressed.connect(SceneManager.quit_game)
	# Makes the menu playable with the keyboard alone.
	_play_button.grab_focus()
