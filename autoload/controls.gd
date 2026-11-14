extends Node
## Registers every gameplay input action.
##
## The bindings live here rather than in project.godot because an input map
## serialised by the editor is unreadable in a diff: one key is a 300-character
## line. As a table it can be reviewed, and adding a gamepad button is one entry.

const KEYS: Dictionary[StringName, Array] = {
	&"move_forward": [KEY_W, KEY_UP],
	&"move_back": [KEY_S, KEY_DOWN],
	&"move_left": [KEY_A, KEY_LEFT],
	&"move_right": [KEY_D, KEY_RIGHT],
	&"jump": [KEY_SPACE],
	&"camera_left": [KEY_Q],
	&"camera_right": [KEY_E],
	&"restart": [KEY_R],
	&"pause": [KEY_ESCAPE, KEY_P],
}

const PAD_BUTTONS: Dictionary[StringName, JoyButton] = {
	&"jump": JOY_BUTTON_A,
	&"restart": JOY_BUTTON_BACK,
	&"pause": JOY_BUTTON_START,
}

## Action -> [axis, direction].
const PAD_AXES: Dictionary[StringName, Array] = {
	&"move_forward": [JOY_AXIS_LEFT_Y, -1.0],
	&"move_back": [JOY_AXIS_LEFT_Y, 1.0],
	&"move_left": [JOY_AXIS_LEFT_X, -1.0],
	&"move_right": [JOY_AXIS_LEFT_X, 1.0],
	&"camera_left": [JOY_AXIS_RIGHT_X, -1.0],
	&"camera_right": [JOY_AXIS_RIGHT_X, 1.0],
}


func _ready() -> void:
	for action: StringName in KEYS:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.2)
		for keycode: Key in KEYS[action]:
			var key := InputEventKey.new()
			key.physical_keycode = keycode
			InputMap.action_add_event(action, key)
	for action: StringName in PAD_BUTTONS:
		var button := InputEventJoypadButton.new()
		button.button_index = PAD_BUTTONS[action]
		InputMap.action_add_event(action, button)
	for action: StringName in PAD_AXES:
		var motion := InputEventJoypadMotion.new()
		motion.axis = PAD_AXES[action][0]
		motion.axis_value = PAD_AXES[action][1]
		InputMap.action_add_event(action, motion)
