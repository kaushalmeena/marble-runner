extends "res://scripts/Obstacle.gd"

signal collected


func _check_collision() -> void:
	if get_slide_count() > 0:
		emit_signal("collected")
		queue_free()
