extends Control
## Audio and accessibility preferences.

@onready var _volume_slider: HSlider = %VolumeSlider
@onready var _volume_value: Label = %VolumeValue
@onready var _reduced_motion: CheckButton = %ReducedMotionToggle
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_volume_slider.value = Settings.sfx_volume * 100.0
	_reduced_motion.button_pressed = Settings.reduced_motion
	_show_volume()

	_volume_slider.value_changed.connect(_on_volume_changed)
	_reduced_motion.toggled.connect(_on_reduced_motion_toggled)
	_back_button.pressed.connect(_leave)
	_back_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_leave()


func _on_volume_changed(value: float) -> void:
	Settings.sfx_volume = value / 100.0
	_show_volume()
	# Play something so the new level is audible while dragging.
	Audio.play(&"pickup", -2.0)


func _on_reduced_motion_toggled(pressed: bool) -> void:
	Settings.reduced_motion = pressed


func _show_volume() -> void:
	_volume_value.text = "%d%%" % roundi(Settings.sfx_volume * 100.0)


func _leave() -> void:
	Settings.save_settings()
	SceneManager.goto_main_menu()
