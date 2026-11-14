extends Node
## Single place that knows which scenes exist and how to move between them.

const MAIN_MENU := "res://ui/main_menu.tscn"
const LEVEL_SELECT := "res://ui/level_select.tscn"
const GAME := "res://game/game.tscn"
const SHOP_MENU := "res://ui/shop_menu.tscn"
## The screen dips to this colour between scenes.
const SHADE := Color(0.02, 0.04, 0.08)
const FADE_OUT_SECONDS := 0.16
const FADE_IN_SECONDS := 0.28

var _shade := ColorRect.new()
var _switching: bool = false


func _ready() -> void:
	# Scenes are left from the pause menu too, with the tree frozen.
	process_mode = Node.PROCESS_MODE_ALWAYS
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_shade.color = Color(SHADE, 0.0)
	_shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_shade)


func goto_main_menu() -> void:
	_change_scene(MAIN_MENU)


func goto_level_select() -> void:
	_change_scene(LEVEL_SELECT)


## Starts [param index], or restarts it if it is already the one being played.
func play_level(index: int) -> void:
	GameState.current_level = clampi(index, 0, LevelCatalog.count() - 1)
	# Coming back to the level select lands on the page this level is on.
	GameState.level_page = LevelCatalog.page_of(GameState.current_level)
	_change_scene(GAME)


func restart_level() -> void:
	play_level(GameState.current_level)


## Picks up where the player left off.
func continue_game() -> void:
	play_level(GameState.next_unbeaten())


func goto_shop() -> void:
	_change_scene(SHOP_MENU)


func quit_game() -> void:
	GameState.save_progress()
	get_tree().quit()


## Dips to black, swaps the scene, and comes back up. The pause is lifted and
## the mouse freed at the swap, otherwise a scene entered from the pause menu
## would start frozen with no cursor.
func _change_scene(path: String) -> void:
	if _switching:
		return
	_switching = true
	# Swallows clicks, so nothing on the outgoing screen can be pressed twice.
	_shade.mouse_filter = Control.MOUSE_FILTER_STOP
	var out := create_tween()
	out.tween_property(_shade, ^"color:a", 1.0, FADE_OUT_SECONDS)
	await out.finished
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var error := get_tree().change_scene_to_file(path)
	if error != OK:
		push_error("Could not change to scene %s (error %d)." % [path, error])
	# The new scene is swapped in at the end of the frame and draws on the next.
	await get_tree().process_frame
	await get_tree().process_frame
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_switching = false
	create_tween().tween_property(_shade, ^"color:a", 0.0, FADE_IN_SECONDS)
