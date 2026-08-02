extends Node
## Player preferences, kept apart from progress.
##
## These live in their own file rather than in [GameState]'s: two autoloads
## writing one ConfigFile would race and silently drop each other's changes.

signal changed

const SAVE_PATH := "user://settings.cfg"
const SECTION := "settings"

## Silence below this is treated as muted, since -80 dB is not audibly zero.
const MIN_VOLUME_DB := -40.0

var sfx_volume: float = 0.8:
	set(value):
		var clamped := clampf(value, 0.0, 1.0)
		if is_equal_approx(sfx_volume, clamped):
			return
		sfx_volume = clamped
		_apply_volume()
		changed.emit()

## Disables camera shake. Shake is the sort of effect that makes some people
## motion sick, and there was no way to turn it off.
var reduced_motion: bool = false:
	set(value):
		if reduced_motion == value:
			return
		reduced_motion = value
		changed.emit()


func _ready() -> void:
	load_settings()
	_apply_volume()


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	sfx_volume = float(config.get_value(SECTION, "sfx_volume", 0.8))
	reduced_motion = bool(config.get_value(SECTION, "reduced_motion", false))


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value(SECTION, "sfx_volume", sfx_volume)
	config.set_value(SECTION, "reduced_motion", reduced_motion)
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("Could not save settings to %s (error %d)." % [SAVE_PATH, error])


func _apply_volume() -> void:
	var bus := AudioServer.get_bus_index(&"Master")
	if bus < 0:
		return
	AudioServer.set_bus_mute(bus, sfx_volume <= 0.001)
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(0.0001, sfx_volume)))
