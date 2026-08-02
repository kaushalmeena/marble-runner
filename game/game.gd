extends Node3D
## Gameplay root. Wires the track, the player, the power-ups and the HUD
## together, and owns the end-of-run sequence.
##
## Everything here is a connection or a hand-off. The track does not know about
## the player, the player does not know about the score, the power-up manager
## only counts down, and the HUD only reads. What each power-up actually *does*
## is decided here, next to the objects it affects.

## How long the crash is held on screen before the death menu, so the player can
## see what hit them. The Godot 3 version cut away on the same frame.
const DEATH_HOLD_SECONDS := 0.55

@export_group("Power-up tuning")
## How far the magnet reaches for fruit, in world units.
@export var magnet_radius: float = 15.0
## How fast the magnet drags fruit in, in units/second.
@export var magnet_pull: float = 28.0
## Scroll speed multiplier while slow-mo runs.
@export var slow_mo_scale: float = 0.55

@onready var _track: Track = $Track
@onready var _marble: Marble = $Marble
@onready var _hud: Hud = $HUDLayer/Hud
@onready var _power_ups: PowerUpManager = $PowerUpManager

var _is_over: bool = false


func _ready() -> void:
	_marble.configure(_track.lanes)
	_marble.hit_obstacle.connect(_on_marble_hit_obstacle)
	_marble.collected_pickup.connect(_on_marble_collected_pickup)
	_marble.collected_power_up.connect(_on_marble_collected_power_up)
	_marble.jumped.connect(_on_marble_jumped)
	_marble.landed.connect(_on_marble_landed)
	_power_ups.activated.connect(_on_power_up_activated)
	_power_ups.expired.connect(_on_power_up_expired)
	_hud.bind_run(_track, _power_ups)


func _physics_process(_delta: float) -> void:
	# The world scrolls past a stationary marble, so the marble cannot work out
	# its own spin rate: it has to be told.
	_marble.forward_speed = _track.speed


func _on_marble_collected_pickup(pickup: Area3D) -> void:
	GameState.add_score()
	_track.recycle(pickup)
	_hud.pop_score()
	Audio.play(&"pickup", 0.0, 0.06)


func _on_marble_collected_power_up(pickup: Area3D) -> void:
	var power_up := pickup as PowerUpPickup
	if power_up != null:
		_power_ups.activate(power_up.kind)
	_track.recycle(pickup)
	Audio.play(&"power_up")


func _on_marble_jumped() -> void:
	Audio.play(&"jump", -4.0, 0.05)


func _on_marble_landed() -> void:
	Audio.play(&"land", -8.0, 0.05)


func _on_power_up_activated(kind: PowerUps.Kind, _duration: float) -> void:
	match kind:
		PowerUps.Kind.SHIELD:
			_marble.set_shielded(true)
		PowerUps.Kind.MAGNET:
			_track.set_magnet(_marble, magnet_radius, magnet_pull)
		PowerUps.Kind.SLOW_MO:
			_track.speed_scale = slow_mo_scale


func _on_power_up_expired(kind: PowerUps.Kind) -> void:
	match kind:
		PowerUps.Kind.SHIELD:
			_marble.set_shielded(false)
		PowerUps.Kind.MAGNET:
			_track.clear_magnet()
		PowerUps.Kind.SLOW_MO:
			_track.speed_scale = 1.0
	if not _is_over:
		Audio.play(&"power_down", -6.0)


func _on_marble_hit_obstacle(obstacle: Area3D) -> void:
	if _is_over:
		return
	# A live shield turns the hit into a save: it is spent, the obstacle is
	# cleared out of the way, and the run carries on.
	if _power_ups.consume_shield():
		_track.recycle(obstacle)
		_hud.show_shield_save()
		Audio.play(&"shield_break")
		return
	_end_run()


func _end_run() -> void:
	_is_over = true
	_track.stop()
	_marble.stop()
	_power_ups.clear_all()
	_hud.show_crash()
	Audio.play(&"crash")
	GameState.run_distance = _track.distance
	await get_tree().create_timer(DEATH_HOLD_SECONDS).timeout
	SceneManager.show_death_menu()
