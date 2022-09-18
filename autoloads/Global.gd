extends Node

export(int) var score: int = 0
export(int) var best_score: int = 0

var current_scene = null

var score_file = "user://score.save"


func show_death_menu() -> void:
	save_score()
	goto_scene("res://menus/DeathMenu.tscn")


func show_main_menu() -> void:
	save_score()
	goto_scene("res://menus/MainMenu.tscn")


func start_game() -> void:
	score = 0
	goto_scene("res://game/Game.tscn")


func goto_scene(path: String) -> void:
	call_deferred("_deferred_goto_scene", path)


func save_score():
	var file: File = File.new()
	if score > best_score:
		file.open(score_file, File.WRITE)
		file.store_var(score)
		file.close()


func load_score():
	var file: File = File.new()
	if file.file_exists(score_file):
		file.open(score_file, File.READ)
		best_score = file.get_var()
		file.close()


func _deferred_goto_scene(path: String) -> void:
	current_scene.free()
	var scene: PackedScene = ResourceLoader.load(path)
	current_scene = scene.instance()
	get_tree().root.add_child(current_scene)
	get_tree().current_scene = current_scene


func _init_current_scene() -> void:
	var root: Node = get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)


func _ready() -> void:
	load_score()
	_init_current_scene()
