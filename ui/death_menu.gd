extends Control
## End-of-run summary.

@onready var _score_value: Label = %ScoreValue
@onready var _best_value: Label = %BestValue
@onready var _distance_value: Label = %DistanceValue
@onready var _record_label: Label = %RecordLabel
@onready var _retry_button: Button = %RetryButton
@onready var _menu_button: Button = %MenuButton


func _ready() -> void:
	_score_value.text = str(GameState.score)
	_best_value.text = str(GameState.best_score)
	_distance_value.text = "%d m" % int(GameState.run_distance)
	_record_label.visible = GameState.is_new_record()
	_retry_button.pressed.connect(SceneManager.start_game)
	_menu_button.pressed.connect(SceneManager.goto_main_menu)
	_retry_button.grab_focus()
