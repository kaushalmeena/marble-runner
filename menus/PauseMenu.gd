extends Control

var is_paused = false setget set_is_paused

func _input(event):
	if event is InputEventKey and event.is_action_released("ui_cancel"):
		self.is_paused = !is_paused
		
		
func set_is_paused(value):
	is_paused = value
	get_tree().paused = value
	visible = value


func _on_Resume_button_up():
	self.is_paused = false


func _on_MainMenu_button_up():
	self.is_paused = false
	Global.goto_scene('res://menus/MainMenu.tscn')
