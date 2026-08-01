extends Node3D
## Gameplay root. Wires the track, the player and the HUD together and owns the
## end-of-run sequence.
##
## Everything here is a connection or a hand-off: the track does not know about
## the player, the player does not know about the score, and the HUD only reads.

## How long the crash is held on screen before the game over menu, so the player
## can see what hit them. The Godot 3 version cut away on the same frame.
const DEATH_HOLD_SECONDS := 0.55

@onready var _track: Track = $Track
@onready var _marble: Marble = $Marble
@onready var _hud: Hud = $HUDLayer/Hud

var _is_over: bool = false


func _ready() -> void:
	_marble.configure(_track.lanes)
	_marble.hit_obstacle.connect(_on_marble_hit_obstacle)
	_marble.collected_pickup.connect(_on_marble_collected_pickup)
	_hud.bind_track(_track)


func _physics_process(_delta: float) -> void:
	# The world scrolls past a stationary marble, so the marble cannot work out
	# its own spin rate: it has to be told.
	_marble.forward_speed = _track.speed


func _on_marble_collected_pickup(pickup: Area3D) -> void:
	GameState.add_score()
	_track.recycle(pickup)
	_hud.pop_score()


func _on_marble_hit_obstacle() -> void:
	if _is_over:
		return
	_is_over = true
	_track.stop()
	_marble.stop()
	_hud.show_crash()
	GameState.run_distance = _track.distance
	await get_tree().create_timer(DEATH_HOLD_SECONDS).timeout
	SceneManager.show_death_menu()
