extends Node

var score: int = 0
var best_score: int = 0

var current_scene = null


func goto_scene(path: String):
	call_deferred("_deferred_goto_scene", path)


func _deferred_goto_scene(path: String):
	current_scene.free()
	var scene: PackedScene = ResourceLoader.load(path)
	current_scene = scene.instance()
	get_tree().root.add_child(current_scene)
	get_tree().current_scene = current_scene


func _init_current_scene() -> void:
	var root: Node = get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)


func _ready() -> void:
	_init_current_scene()
