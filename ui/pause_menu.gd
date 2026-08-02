extends Control
## Pause overlay. Owns the paused state of the tree while it is on screen.
##
## The root node's process mode is ALWAYS, which is what lets this script keep
## receiving input after it has frozen everything else.

@onready var _resume_button: Button = %ResumeButton
@onready var _menu_button: Button = %MenuButton


func _ready() -> void:
	hide()
	_resume_button.pressed.connect(resume)
	_menu_button.pressed.connect(SceneManager.goto_main_menu)


## Alt-tabbing mid-run used to be a death sentence: the world kept scrolling
## while the window was in the background.
func _notification(what: int) -> void:
	if what != NOTIFICATION_APPLICATION_FOCUS_OUT \
			and what != NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		return
	if is_node_ready() and not visible and is_inside_tree():
		pause()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"pause"):
		return
	get_viewport().set_input_as_handled()
	if visible:
		resume()
	else:
		pause()


func pause() -> void:
	get_tree().paused = true
	show()
	_resume_button.grab_focus()


func resume() -> void:
	get_tree().paused = false
	hide()
