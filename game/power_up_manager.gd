class_name PowerUpManager
extends Node
## Tracks which power-ups are running and for how much longer.
##
## The manager owns only the timers. What a power-up actually *does* is wired up
## in [code]game.gd[/code] from the signals below, so the effects stay next to
## the objects they affect instead of being buried in here.

signal activated(kind: PowerUps.Kind, duration: float)
signal expired(kind: PowerUps.Kind)
## The shield absorbed a hit rather than timing out.
signal shield_consumed

var _remaining: Dictionary[int, float] = {}


func _process(delta: float) -> void:
	if _remaining.is_empty():
		return
	# keys() returns a copy, so erasing inside the loop is safe.
	for kind: int in _remaining.keys():
		var left: float = _remaining[kind] - delta
		if left > 0.0:
			_remaining[kind] = left
			continue
		_remaining.erase(kind)
		expired.emit(kind)


## Starts a power-up, or refreshes it back to full if it is already running.
func activate(kind: PowerUps.Kind) -> void:
	var duration := PowerUps.duration(kind)
	if duration <= 0.0:
		return
	_remaining[kind] = duration
	activated.emit(kind, duration)


func is_active(kind: PowerUps.Kind) -> bool:
	return _remaining.get(kind, 0.0) > 0.0


func time_left(kind: PowerUps.Kind) -> float:
	return _remaining.get(kind, 0.0)


## How much of the power-up is left, 0..1, for the HUD chip bars.
func fraction_left(kind: PowerUps.Kind) -> float:
	var duration := PowerUps.duration(kind)
	if duration <= 0.0:
		return 0.0
	return clampf(time_left(kind) / duration, 0.0, 1.0)


## Spends the shield on a hit. Returns whether there was one to spend.
func consume_shield() -> bool:
	if not is_active(PowerUps.Kind.SHIELD):
		return false
	_remaining.erase(PowerUps.Kind.SHIELD)
	shield_consumed.emit()
	expired.emit(PowerUps.Kind.SHIELD)
	return true


## Ends everything at once, so the run's effects do not outlive the run.
func clear_all() -> void:
	for kind: int in _remaining.keys():
		_remaining.erase(kind)
		expired.emit(kind)
