extends Spatial

var rng = RandomNumberGenerator.new()

var Tree1 = preload("res://objects/Tree1.tscn")
var Tree2 = preload("res://objects/Tree2.tscn")
var Bush1 = preload("res://objects/Bush1.tscn")
var Bush2 = preload("res://objects/Bush2.tscn")
var Bush3 = preload("res://objects/Bush3.tscn")
var Fruit = preload("res://objects/Fruit.tscn")

var Length_1_Obstacles_Data: Array = [1, [Tree1, Bush1]]
var Length_2_Obstacles_Data: Array = [2, [Tree2, Bush2]]
var Length_3_Obstacles_Data: Array = [3, [Bush3]]

export(float) var speed: float = 10.0
export(PoolIntArray) var lanes: PoolIntArray = [-10, -5, 0, 5, 10]

onready var score_board: Control = $HUDLayer/ScoreBoard
onready var timer: Timer = $Timer

var counter: int = 0
var max_count: int = 50


func _get_random_obstacles_data() -> Array:
	var random_float = rng.randf()
	if random_float < 0.6:
		return Length_1_Obstacles_Data
	elif random_float < 0.8:
		return Length_2_Obstacles_Data
	else:
		return Length_3_Obstacles_Data


func _get_random_lane(random_obstacle_len = 1) -> int:
	var random_lane: int = lanes[rng.randi() % (lanes.size() - random_obstacle_len + 1)]
	return random_lane


func _get_random_obstacle_data() -> Array:
	var random_obstacles_data: Array = _get_random_obstacles_data()
	var random_obstacle_len: int = random_obstacles_data[0]
	var random_obstacle_arr: Array = random_obstacles_data[1]
	var RandomObstacle: PackedScene = random_obstacle_arr[rng.randi() % random_obstacle_arr.size()]
	return [random_obstacle_len, RandomObstacle]


func _add_obstacle():
	var random_obstacle_data: Array = _get_random_obstacle_data()
	var random_obstacle_len: int = random_obstacle_data[0]
	var RandomObstacle: PackedScene = random_obstacle_data[1]
	var lane: int = _get_random_lane(random_obstacle_len)
	var obstacle = RandomObstacle.instance()
	obstacle.transform.origin = Vector3(lane, 0, -60)
	add_child(obstacle)


func _add_collectible():
	var lane: int = _get_random_lane()
	var fruit = Fruit.instance()
	fruit.connect("collected", score_board, "increase_score")
	fruit.transform.origin = Vector3(lane, 0, -60)
	add_child(fruit)


func _ready():
	pass


func _on_Timer_timeout():
	if counter % 30 == 0:
		speed = speed * 1.2
	if counter % 40 == 0:
		var new_wait_time = max(0.2, timer.wait_time * 0.9)
		timer.set_wait_time(new_wait_time)
	if counter % 2 == 0:
		_add_obstacle()
	else:
		_add_collectible()
	counter = (counter + 1) % max_count
