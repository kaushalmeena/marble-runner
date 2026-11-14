extends Node
## Single place that knows which scenes exist and how to move between them.

const MAIN_MENU := "res://ui/main_menu.tscn"
const LEVEL_SELECT := "res://ui/level_select.tscn"
const GAME := "res://game/game.tscn"
const SHOP_MENU := "res://ui/shop_menu.tscn"
const SETTINGS := "res://ui/settings_menu.tscn"


func goto_main_menu() -> void:
	_change_scene(MAIN_MENU)


func goto_level_select() -> void:
	_change_scene(LEVEL_SELECT)


## Starts [param index], or restarts it if it is already the one being played.
func play_level(index: int) -> void:
	GameState.current_level = clampi(index, 0, LevelCatalog.count() - 1)
	_change_scene(GAME)


func restart_level() -> void:
	play_level(GameState.current_level)


## Picks up where the player left off.
func continue_game() -> void:
	play_level(GameState.next_unbeaten())


func goto_shop() -> void:
	_change_scene(SHOP_MENU)


func goto_settings() -> void:
	_change_scene(SETTINGS)


func quit_game() -> void:
	GameState.save_progress()
	get_tree().quit()


## Always lifts the pause and frees the mouse before switching, otherwise a
## scene entered from the pause menu would start frozen with no cursor.
func _change_scene(path: String) -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var error := get_tree().change_scene_to_file(path)
	if error != OK:
		push_error("Could not change to scene %s (error %d)." % [path, error])
