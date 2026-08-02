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
## Fallback burst colour, used if the equipped skin has no accent.
const PICKUP_BURST_COLOR := Color(1, 0.78, 0.2)

@export_group("Power-up tuning")
## How far the magnet reaches for fruit, in world units.
@export var magnet_radius: float = 15.0
## How fast the magnet drags fruit in, in units/second.
@export var magnet_pull: float = 28.0
## Scroll speed multiplier while slow-mo runs.
@export var slow_mo_scale: float = 0.55

@export_group("Effect tuning")
## Scroll speed multiplier while boosting.
@export var boost_scale: float = 1.55
## Take-off multiplier for the high-jump power-up. At 1.45 the apex clears the
## two-unit bushes that are otherwise solid.
@export var super_jump_scale: float = 1.45
## Lane-change multiplier while sluggish.
@export var sluggish_scale: float = 0.4
## Sight distance, in units, while fogged.
@export var fog_depth_begin: float = 16.0
@export var fog_depth_end: float = 46.0

@export_group("Start")
## Steps shown before control is handed over. The last one is the "go".
@export var countdown_steps: PackedStringArray = PackedStringArray(["3", "2", "1", "GO"])
@export var countdown_step_seconds: float = 0.6

@onready var _track: Track = $Track
@onready var _marble: Marble = $Marble
@onready var _hud: Hud = $HUDLayer/Hud
@onready var _power_ups: PowerUpManager = $PowerUpManager
@onready var _camera: GameCamera = $Camera3D
@onready var _bursts: BurstEmitter = $BurstEmitter
@onready var _swipes: SwipeDetector = $SwipeDetector
@onready var _biomes: BiomeDirector = $BiomeDirector
@onready var _world_environment: WorldEnvironment = $WorldEnvironment

var _is_over: bool = false
var _pickup_burst_color: Color = PICKUP_BURST_COLOR
var _clear_fog_begin: float = 0.0
var _clear_fog_end: float = 0.0


func _ready() -> void:
	var skin := SkinLibrary.load_default().get_skin(GameState.selected_skin)
	if skin != null:
		_pickup_burst_color = skin.accent_color
	var environment := _world_environment.environment
	_clear_fog_begin = environment.fog_depth_begin
	_clear_fog_end = environment.fog_depth_end
	_marble.configure(_track.lanes)
	_marble.hit_obstacle.connect(_on_marble_hit_obstacle)
	_marble.collected_pickup.connect(_on_marble_collected_pickup)
	_marble.collected_power_up.connect(_on_marble_collected_power_up)
	_marble.jumped.connect(_on_marble_jumped)
	_marble.landed.connect(_on_marble_landed)
	_marble.near_missed.connect(_on_marble_near_missed)
	_power_ups.activated.connect(_on_power_up_activated)
	_power_ups.expired.connect(_on_power_up_expired)
	_track.collectible_missed.connect(_on_collectible_missed)
	_swipes.swiped_left.connect(_marble.shift_lane.bind(-1))
	_swipes.swiped_right.connect(_marble.shift_lane.bind(1))
	_swipes.swiped_up.connect(_marble.try_jump)
	_swipes.tapped.connect(_marble.try_jump)
	_hud.bind_run(_track, _power_ups)
	_biomes.bind_track(_track)
	_run_countdown()


## Holds the world still until the player has had a moment to read the track.
func _run_countdown() -> void:
	for index in countdown_steps.size():
		var step := countdown_steps[index]
		_hud.show_countdown(step)
		Audio.play(&"go" if index == countdown_steps.size() - 1 else &"count", -3.0)
		await get_tree().create_timer(countdown_step_seconds).timeout
		if not is_inside_tree():
			return
	_hud.hide_countdown()
	_track.start()
	_marble.begin()


func _physics_process(_delta: float) -> void:
	# The world scrolls past a stationary marble, so the marble cannot work out
	# its own spin rate: it has to be told.
	_marble.forward_speed = _track.speed


func _on_marble_collected_pickup(pickup: Area3D) -> void:
	GameState.collect_pickup()
	_bursts.burst(pickup.global_position + Vector3.UP, _pickup_burst_color)
	_track.recycle(pickup)
	_hud.pop_score()
	Audio.play(&"pickup", 0.0, 0.06)


func _on_collectible_missed() -> void:
	GameState.break_streak()


func _on_marble_near_missed() -> void:
	if _is_over:
		return
	GameState.score_near_miss()
	_hud.show_near_miss()
	Audio.play(&"near_miss", -8.0)


func _on_marble_collected_power_up(pickup: Area3D) -> void:
	var power_up := pickup as PowerUpPickup
	if power_up != null:
		_power_ups.activate(power_up.kind)
		_bursts.burst(pickup.global_position + Vector3.UP, PowerUps.color(power_up.kind))
	_track.recycle(pickup)
	var hostile := power_up != null and PowerUps.is_debuff(power_up.kind)
	Audio.play(&"debuff" if hostile else &"power_up")
	if hostile:
		# A debuff should register as a mistake, not a reward.
		_camera.add_trauma(0.35)
		_hud.show_debuff(PowerUps.label(power_up.kind))


func _on_marble_jumped() -> void:
	Audio.play(&"jump", -4.0, 0.05)


func _on_marble_landed() -> void:
	_camera.add_trauma(0.16)
	Audio.play(&"land", -8.0, 0.05)


func _on_power_up_activated(kind: PowerUps.Kind, _duration: float) -> void:
	match kind:
		PowerUps.Kind.SHIELD:
			_marble.set_shielded(true)
		PowerUps.Kind.MAGNET:
			_track.set_magnet(_marble, magnet_radius, magnet_pull)
		PowerUps.Kind.SLOW_MO:
			_track.speed_scale = slow_mo_scale
		PowerUps.Kind.BOOST:
			# Boost also grants immunity. A pure speed buff would just be a way
			# to die sooner, which is what the debuffs are for.
			_track.speed_scale = boost_scale
			_marble.set_shielded(true)
		PowerUps.Kind.SUPER_JUMP:
			_marble.set_jump_scale(super_jump_scale)
		PowerUps.Kind.FOG:
			_set_fog(fog_depth_begin, fog_depth_end)
		PowerUps.Kind.SLUGGISH:
			_marble.set_lane_speed_scale(sluggish_scale)
		PowerUps.Kind.REVERSED:
			_marble.set_inverted(true)


func _on_power_up_expired(kind: PowerUps.Kind) -> void:
	match kind:
		PowerUps.Kind.SHIELD:
			# Boost also raises the bubble, so only drop it if neither is left.
			if not _power_ups.is_active(PowerUps.Kind.BOOST):
				_marble.set_shielded(false)
		PowerUps.Kind.MAGNET:
			_track.clear_magnet()
		PowerUps.Kind.SLOW_MO:
			_track.speed_scale = 1.0
		PowerUps.Kind.BOOST:
			_track.speed_scale = 1.0
			if not _power_ups.is_active(PowerUps.Kind.SHIELD):
				_marble.set_shielded(false)
		PowerUps.Kind.SUPER_JUMP:
			_marble.set_jump_scale(1.0)
		PowerUps.Kind.FOG:
			_set_fog(_clear_fog_begin, _clear_fog_end)
		PowerUps.Kind.SLUGGISH:
			_marble.set_lane_speed_scale(1.0)
		PowerUps.Kind.REVERSED:
			_marble.set_inverted(false)
	if not _is_over:
		Audio.play(&"power_down", -6.0)


func _set_fog(begin: float, end: float) -> void:
	var environment := _world_environment.environment
	environment.fog_depth_begin = begin
	environment.fog_depth_end = end


func _on_marble_hit_obstacle(obstacle: Area3D) -> void:
	if _is_over:
		return
	# A live shield turns the hit into a save: it is spent, the obstacle is
	# cleared out of the way, and the run carries on.
	# Boosting is immunity too, and it does not get spent.
	if _power_ups.is_active(PowerUps.Kind.BOOST):
		_bursts.burst(_marble.global_position, PowerUps.color(PowerUps.Kind.BOOST))
		_track.recycle(obstacle)
		_camera.add_trauma(0.3)
		return
	if _power_ups.consume_shield():
		_bursts.burst(_marble.global_position, PowerUps.color(PowerUps.Kind.SHIELD))
		_track.recycle(obstacle)
		_camera.add_trauma(0.45)
		_hud.show_shield_save()
		Audio.play(&"shield_break")
		return
	_end_run()


func _end_run() -> void:
	_is_over = true
	_track.stop()
	_marble.stop()
	_power_ups.clear_all()
	_set_fog(_clear_fog_begin, _clear_fog_end)
	_hud.show_crash()
	_camera.add_trauma(1.0)
	Audio.play(&"crash")
	GameState.run_distance = _track.distance
	await get_tree().create_timer(DEATH_HOLD_SECONDS).timeout
	SceneManager.show_death_menu()
