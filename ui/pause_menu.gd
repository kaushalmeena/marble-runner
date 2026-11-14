extends Control
## Pause overlay. Owns the paused state of the tree while it is on screen.
##
## The root node's process mode is ALWAYS, which is what lets this script keep
## receiving input after it has frozen everything else.

@onready var _resume_button: Button = %ResumeButton
@onready var _restart_button: Button = %RestartButton
@onready var _levels_button: Button = %LevelsButton
@onready var _menu_button: Button = %MenuButton
@onready var _dim: ColorRect = %Dim
@onready var _center: Control = %Center
@onready var _hint: Label = %Hint

## How far below its resting place the card starts, and how long it takes.
const RISE := 28.0
const OPEN_SECONDS := 0.24
const CLOSE_SECONDS := 0.14

var _open: bool = false
var _tween: Tween


func _ready() -> void:
	hide()
	for part: CanvasItem in [_dim, _hint, _center]:
		part.modulate.a = 0.0
	_center.position.y = RISE
	Ui.decorate(_resume_button, Icon.Kind.PLAY)
	Ui.decorate(_restart_button, Icon.Kind.RESTART)
	Ui.decorate(_levels_button, Icon.Kind.LEVELS)
	Ui.decorate(_menu_button, Icon.Kind.HOME)
	_resume_button.pressed.connect(resume)
	_restart_button.pressed.connect(SceneManager.restart_level)
	_levels_button.pressed.connect(SceneManager.goto_level_select)
	_menu_button.pressed.connect(SceneManager.goto_main_menu)


## Alt-tabbing mid-level pauses, so the clock does not run while the window is
## in the background.
func _notification(what: int) -> void:
	if what != NOTIFICATION_APPLICATION_FOCUS_OUT \
			and what != NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		return
	if is_node_ready() and not _open and is_inside_tree():
		pause()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"pause"):
		return
	get_viewport().set_input_as_handled()
	if _open:
		resume()
	else:
		pause()


func pause() -> void:
	_open = true
	get_tree().paused = true
	# Free the pointer if mouse look had captured it, or the menu is unclickable.
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	show()
	_resume_button.grab_focus()
	# The view dims while the card comes up from just below where it rests.
	_restart_tween()
	_tween.tween_property(_dim, ^"modulate:a", 1.0, OPEN_SECONDS)
	_tween.tween_property(_hint, ^"modulate:a", 1.0, OPEN_SECONDS)
	_tween.tween_property(_center, ^"modulate:a", 1.0, OPEN_SECONDS)
	_tween.tween_property(_center, ^"position:y", 0.0, OPEN_SECONDS) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## The game picks up at once; the overlay clears away over the top of it.
func resume() -> void:
	_open = false
	get_tree().paused = false
	get_viewport().gui_release_focus()
	_restart_tween()
	_tween.tween_property(_dim, ^"modulate:a", 0.0, CLOSE_SECONDS)
	_tween.tween_property(_hint, ^"modulate:a", 0.0, CLOSE_SECONDS)
	_tween.tween_property(_center, ^"modulate:a", 0.0, CLOSE_SECONDS)
	_tween.tween_property(_center, ^"position:y", RISE, CLOSE_SECONDS).set_ease(Tween.EASE_IN)
	_tween.chain().tween_callback(hide)


## Starts a fresh animation from wherever the last one had got to, so pausing
## and resuming in quick succession never jumps.
func _restart_tween() -> void:
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_parallel()
