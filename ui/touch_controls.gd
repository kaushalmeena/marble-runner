class_name TouchControls
extends Control
## On-screen stick and buttons, shown only on a touchscreen.
##
## The left half of the screen is a floating stick: it appears wherever the
## thumb lands. It drives the same input actions as the keyboard, so nothing
## else in the game knows touch exists.

const STICK_RADIUS := 90.0
const MOVE_ACTIONS: Array[StringName] = [
	&"move_left", &"move_right", &"move_forward", &"move_back"]

var _stick_touch: int = -1
var _stick_origin := Vector2.ZERO
var _stick_offset := Vector2.ZERO


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = DisplayServer.is_touchscreen_available()
	set_process_input(visible)
	if not visible:
		return
	var buttons := Ui.column(14)
	buttons.mouse_filter = Control.MOUSE_FILTER_PASS
	buttons.add_child(_action_button("USE", &"use_power_up"))
	buttons.add_child(_action_button("JUMP", &"jump"))
	add_child(buttons)
	Ui.pin(buttons, Control.PRESET_BOTTOM_RIGHT, Vector2(30, 120))


func _input(event: InputEvent) -> void:
	var touch := event as InputEventScreenTouch
	if touch != null:
		if touch.pressed and _stick_touch < 0 and touch.position.x < size.x * 0.5:
			_stick_touch = touch.index
			_stick_origin = touch.position
			_stick_offset = Vector2.ZERO
		elif not touch.pressed and touch.index == _stick_touch:
			_stick_touch = -1
			_stick_offset = Vector2.ZERO
			_apply_stick()
		queue_redraw()
		return
	var drag := event as InputEventScreenDrag
	if drag != null and drag.index == _stick_touch:
		_stick_offset = (drag.position - _stick_origin).limit_length(STICK_RADIUS)
		_apply_stick()
		queue_redraw()


func _draw() -> void:
	if _stick_touch < 0:
		return
	draw_circle(_stick_origin, STICK_RADIUS, Color(1, 1, 1, 0.1))
	draw_circle(_stick_origin + _stick_offset, 34.0, Color(1, 1, 1, 0.35))


func _apply_stick() -> void:
	var value := _stick_offset / STICK_RADIUS
	var strengths := [maxf(0.0, -value.x), maxf(0.0, value.x), maxf(0.0, -value.y), maxf(0.0, value.y)]
	for index in MOVE_ACTIONS.size():
		if strengths[index] > 0.05:
			Input.action_press(MOVE_ACTIONS[index], strengths[index])
		else:
			Input.action_release(MOVE_ACTIONS[index])


func _action_button(text: String, action: StringName) -> Button:
	var button := Ui.button(text, 130.0)
	button.custom_minimum_size.y = 84.0
	button.focus_mode = Control.FOCUS_NONE
	button.button_down.connect(Input.action_press.bind(action))
	button.button_up.connect(Input.action_release.bind(action))
	return button
