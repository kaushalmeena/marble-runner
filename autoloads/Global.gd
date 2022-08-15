extends Node

var score = 0
var best_score = 0

var current_scene = null

func _ready():
	init_current_scene()
	
func init_current_scene():
	var root = get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)
	
func goto_scene(path):
	call_deferred("_deferred_goto_scene", path)
	
func _deferred_goto_scene(path):
	current_scene.free()
	var scene = ResourceLoader.load(path)
	current_scene = scene.instance()
	get_tree().root.add_child(current_scene)
	get_tree().current_scene = current_scene
