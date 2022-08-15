extends Control

onready var your_score: Label = $ColorRect/CenterContainer/VBoxContainer/CenterContainer/VBoxContainer/YourScore
onready var best_score: Label = $ColorRect/CenterContainer/VBoxContainer/CenterContainer/VBoxContainer/BestScore


func _init_scores() -> void:
	your_score.text = "Your Score: %s" % Global.score
	best_score.text = "Best Score: %s" % Global.best_score


func _ready() -> void:
	_init_scores()


func _on_Restart_button_up() -> void:
	Global.goto_scene("res://game/Game.tscn")


func _on_MainMenu_button_up() -> void:
	Global.goto_scene("res://menus/MainMenu.tscn")
