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
