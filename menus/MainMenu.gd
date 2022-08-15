extends Control

onready var best_score: Label = $ColorRect/CenterContainer/VBoxContainer/CenterContainer/BestScore

func _init_score():
	best_score.text = 'Best Score: %s' % Global.best_score

func _ready():
	_init_score()

func _on_Play_button_up():
	Global.goto_scene('res://game/Game.tscn')

func _on_Quit_button_up():
	get_tree().quit()
