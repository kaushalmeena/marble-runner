class_name Cheats
extends Node
## Typed cheat codes, in the spirit of the old ones: no menu, no prompt, just
## type the word during play.
##
## This node only recognises words. It keeps the last few letters typed and
## reports a code when the tail matches one. What a code *does* is decided in
## [code]game.gd[/code], next to the things it changes.
##
## Codes avoid the letters R, P and F, which restart, pause and spend the
## power-up. Typing still rolls the marble about, which is part of the charm.

signal entered(code: StringName)

## Code -> what the HUD says when it lands.
const CODES: Dictionary[StringName, String] = {
	&"MOONBOOTS": "Low gravity",
	&"BUBBLE": "Shield for a minute",
	&"SKYHOOK": "Unlimited air jumps",
	&"ZOOMZOOM": "Faster marble",
	&"TICKTOCK": "Clock stopped for a minute",
	&"ALLGEMS": "Every gem collected",
	&"SKELETONKEY": "Three keys",
	&"BOWLING": "Rival marbles knocked out",
	&"TOOLKIT": "Next power-up in the slot",
	&"GOLDMINE": "500 coins",
	&"ALLACCESS": "Every level unlocked",
}
## Codes that do not touch the run in progress, so using one does not void it.
const HARMLESS: Array[StringName] = [&"GOLDMINE", &"ALLACCESS"]

var _typed: String = ""
var _longest: int = 0


func _ready() -> void:
	for code: StringName in CODES:
		_longest = maxi(_longest, String(code).length())


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	# The physical key, so the codes do not depend on the keyboard layout.
	var code := key.physical_keycode
	if code < KEY_A or code > KEY_Z:
		return
	_typed = (_typed + char(code)).right(_longest)
	for word: StringName in CODES:
		if _typed.ends_with(String(word)):
			_typed = ""
			entered.emit(word)
			return


## True when [param code] changes the run and so voids its time and stars.
static func voids_run(code: StringName) -> bool:
	return not HARMLESS.has(code)
