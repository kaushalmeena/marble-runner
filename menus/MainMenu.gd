extends Control

onready var best_score: Label = $ColorRect/CenterContainer/VBoxContainer/CenterContainer/BestScore


func _init_score() -> void:
	best_score.text = "Best Score: %s" % Global.best_score


func _ready() -> void:
	_init_score()


func _on_Play_button_up() -> void:
	Global.goto_scene("res://game/Game.tscn")


func _on_Quit_button_up() -> void:
	get_tree().quit()
