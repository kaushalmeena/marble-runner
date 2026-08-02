class_name RevivePrompt
extends Control
## Offers one more chance, for coins, before the death screen.

## Player paid up.
signal revived
## Player let the offer lapse or waved it away.
signal declined

## How long the offer stands. Short enough to keep the run tense.
const DECIDE_SECONDS := 5.0

@onready var _price_label: Label = %PriceLabel
@onready var _timer_bar: ProgressBar = %TimerBar
@onready var _revive_button: Button = %ReviveButton
@onready var _decline_button: Button = %DeclineButton

var _remaining: float = 0.0


func _ready() -> void:
	hide()
	set_process(false)
	_revive_button.pressed.connect(_accept)
	_decline_button.pressed.connect(_decline)


func _process(delta: float) -> void:
	_remaining = maxf(0.0, _remaining - delta)
	_timer_bar.value = _remaining / DECIDE_SECONDS
	if _remaining <= 0.0:
		_decline()


## Shows the offer. Returns false if there is nothing to offer, in which case
## the caller should go straight to the death screen.
func offer() -> bool:
	if not GameState.can_revive():
		return false
	_price_label.text = "%d COINS" % GameState.revive_price()
	_remaining = DECIDE_SECONDS
	_timer_bar.value = 1.0
	show()
	set_process(true)
	_revive_button.grab_focus()
	return true


func _accept() -> void:
	if not GameState.buy_revive():
		_decline()
		return
	_close()
	revived.emit()


func _decline() -> void:
	_close()
	declined.emit()


func _close() -> void:
	set_process(false)
	hide()
