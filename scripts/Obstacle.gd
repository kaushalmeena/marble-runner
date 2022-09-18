extends KinematicBody

onready var Game = get_node("/root/Game")

var velocity: Vector3 = Vector3.ZERO


func _ready() -> void:
	pass


func _check_collision() -> void:
	if get_slide_count() > 0:
		Global.show_death_menu()


func _check_out_of_bounds() -> void:
	if transform.origin.z > 30:
		queue_free()


func _move() -> void:
	velocity.z = Game.speed
	move_and_slide(velocity, Vector3.UP)


func _physics_process(_delta: float) -> void:
	_move()
	_check_collision()
	_check_out_of_bounds()
