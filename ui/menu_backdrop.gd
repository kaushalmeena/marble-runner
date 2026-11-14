class_name MenuBackdrop
extends Node3D
## A real level, slowly orbited, behind a menu.
##
## The menus are 2D, and a Node3D under them renders behind the interface for
## free. Showing an actual course instead of a gradient means the first thing
## the player sees is the game.

const ENVIRONMENT := preload("res://resources/environments/day_sky.tres")

## Which level to show. Negative picks the furthest one the player has reached.
@export var level_index: int = -1
## Radians per second.
@export var orbit_speed: float = 0.12

var _camera := Camera3D.new()
var _center := Vector3.ZERO
var _radius: float = 30.0
var _angle: float = 0.6


func _ready() -> void:
	var index := level_index if level_index >= 0 else GameState.next_unbeaten()
	var level := LevelCatalog.at(index)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, 35.0, 0.0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	add_child(sun)
	var environment: Environment = ENVIRONMENT.duplicate(true)
	level.biome.apply(environment, sun)
	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)

	var root := Node3D.new()
	add_child(root)
	var builder := LevelBuilder.new(root, level.biome)
	level.build(builder)
	builder.add_scenery(hash(level.id))
	_center = builder.bounds.get_center()
	_radius = maxf(builder.bounds.size.x, builder.bounds.size.z) * 0.55 + 14.0
	_camera.fov = 55.0
	_camera.far = 600.0
	add_child(_camera)
	_place()


func _process(delta: float) -> void:
	_angle += orbit_speed * delta
	_place()


func _place() -> void:
	var eye := _center + Vector3(sin(_angle) * _radius, _radius * 0.45, cos(_angle) * _radius)
	_camera.look_at_from_position(eye, _center)
