extends Node
## Single place that knows which scenes exist and how to move between them.
##
## Godot 4's [method SceneTree.change_scene_to_file] already defers the swap
## until the end of the frame, so the manual free/instantiate/current_scene
## juggling the Godot 3 version needed is gone.

const MAIN_MENU := "res://ui/main_menu.tscn"
const GAME := "res://game/game.tscn"
const GAME_OVER := "res://ui/game_over_menu.tscn"


func goto_main_menu() -> void:
	_change_scene(MAIN_MENU)


func start_game() -> void:
	GameState.reset_run()
	_change_scene(GAME)


func goto_game_over() -> void:
	GameState.commit_run()
	_change_scene(GAME_OVER)


func quit_game() -> void:
	GameState.save_progress()
	get_tree().quit()


## Always lifts the pause before switching, otherwise a scene entered from the
## pause menu would start frozen.
func _change_scene(path: String) -> void:
	get_tree().paused = false
	var error := get_tree().change_scene_to_file(path)
	if error != OK:
		push_error("Could not change to scene %s (error %d)." % [path, error])
