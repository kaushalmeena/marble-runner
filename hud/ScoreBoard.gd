extends Control

onready var score: Label = $MarginContainer/HBoxContainer/Score


func increase_score():
	Global.score += 1
	score.text = var2str(Global.score)


func _ready():
	pass
