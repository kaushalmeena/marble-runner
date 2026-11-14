extends Node3D
## Gameplay root. Builds the level, then referees it: the clock, the gems, the
## power-up slot, falls and the finish.
##
## Everything here is a connection or a hand-off. Gimmicks act on the marble by
## themselves; this script only hears about the things that change the state of
## the run. What each power-up actually *does* is decided here, next to the
## objects it affects.

const ENVIRONMENT := preload("res://resources/environments/day_sky.tres")
const EMPTY := -1
## Pause between crossing the finish and the results card, so the moment lands.
const FINISH_HOLD_SECONDS := 0.9

@export_group("Power-up tuning")
## Take-off speed of the super jump. Roughly three and a half normal jumps high.
@export var super_jump_speed: float = 14.0
@export var boost_speed: float = 20.0
## Gravity multiplier while the feather runs.
@export var feather_gravity: float = 0.3
## How far the magnet reaches for gems, and how fast it drags them in.
@export var magnet_radius: float = 7.0
@export var magnet_pull: float = 16.0

@onready var _world: WorldEnvironment = $WorldEnvironment
@onready var _sun: DirectionalLight3D = $Sun
@onready var _camera: GameCamera = $Camera3D
@onready var _marble: Marble = $Marble
@onready var _bursts: BurstEmitter = $BurstEmitter
@onready var _level_root: Node3D = $Level
@onready var _hud: Hud = $HUDLayer/Hud
@onready var _results: ResultsCard = $ResultsLayer/ResultsCard

var _level: LevelDef
var _builder: LevelBuilder
var _time: float = 0.0
var _running: bool = false
var _finished: bool = false
var _gems_collected: int = 0
var _respawn_position := Vector3.ZERO
var _held: int = EMPTY
## Seconds left on each running effect, keyed by [enum PowerUps.Kind].
var _effects: Dictionary[int, float] = {}
var _seen_kinds: Dictionary[int, bool] = {}


func _ready() -> void:
	_level = LevelCatalog.at(GameState.current_level)
	# A private copy: the palette is written into it, and the shared resource
	# must not carry one level's colours into the next.
	var environment: Environment = ENVIRONMENT.duplicate(true)
	_level.biome.apply(environment, _sun)
	_world.environment = environment

	_builder = LevelBuilder.new(_level_root, _level.biome)
	_level.build(_builder)
	_builder.add_scenery(hash(_level.id))
	_connect_level()

	_respawn_position = _builder.start_position
	_marble.global_position = _respawn_position
	_marble.landed.connect(_on_marble_landed)
	_marble.jumped.connect(_on_marble_jumped)
	_camera.follow(_marble, _builder.start_yaw)

	_hud.setup(GameState.current_level + 1, _level, _builder.gems.size(),
		GameState.best_time(_level))
	_results.next_pressed.connect(_on_next_pressed)
	_results.retry_pressed.connect(SceneManager.restart_level)
	_results.levels_pressed.connect(SceneManager.goto_level_select)
	_run_countdown()


func _connect_level() -> void:
	for gem in _builder.gems:
		gem.collected.connect(_on_gem_collected)
	for pickup in _builder.pickups:
		pickup.taken.connect(_on_pickup_taken)
	for checkpoint in _builder.checkpoints:
		checkpoint.reached.connect(_on_checkpoint_reached)
	for tip in _builder.tips:
		tip.entered.connect(_on_tip_entered)
	for hazard in _builder.hazards:
		hazard.entered.connect(_on_hazard_entered)
	if _builder.finish != null:
		_builder.finish.reached.connect(_on_finish_reached)
		# A level with no gems has nothing to wait for.
		_builder.finish.locked = not _builder.gems.is_empty()


## Holds the marble still while the player reads the level name.
func _run_countdown() -> void:
	_hud.show_banner(_level.title, 0.9)
	Audio.play(&"count", -3.0)
	await get_tree().create_timer(1.2).timeout
	if not is_inside_tree():
		return
	_hud.show_banner("GO", 0.4, Color(0.5, 1.0, 0.65))
	Audio.play(&"go", -3.0)
	_marble.control_enabled = true
	_running = true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"restart"):
		SceneManager.restart_level()
	elif event.is_action_pressed(&"use_power_up"):
		_use_power_up()
	elif event is InputEventMouseButton and event.pressed and not _finished:
		# Mouse look is opt-in: a click captures the pointer, pausing frees it.
		# It has to happen inside an input event or a browser refuses it.
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		return
	get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	_hud.set_time(_time, _effects.has(PowerUps.Kind.STOPWATCH))
	for kind in Hud.EFFECT_KINDS:
		_hud.set_effect(kind, _effects.get(kind, 0.0) / PowerUps.duration(kind))


func _physics_process(delta: float) -> void:
	if not _running:
		return
	if not _effects.has(PowerUps.Kind.STOPWATCH):
		_time += delta
	_tick_effects(delta)
	if _effects.has(PowerUps.Kind.MAGNET):
		_pull_gems(delta)
	if _marble.global_position.y < _builder.fall_limit():
		_respawn()


# --- Gems and the finish ----------------------------------------------------


func _on_gem_collected(gem: Gem) -> void:
	_gems_collected += 1
	var total := _builder.gems.size()
	_hud.set_gems(_gems_collected, total)
	_bursts.burst(gem.global_position + Vector3.UP * Gem.HOVER, gem.color)
	# Each gem rings a little higher than the last, so a level plays a scale.
	Audio.play(&"pickup", 0.0, 0.0, 1.0 + 0.5 * _gems_collected / maxf(1.0, total))
	if _gems_collected >= total:
		_builder.finish.locked = false
		_hud.show_banner("FINISH OPEN", 0.9, FinishPad.OPEN_COLOR)
		Audio.play(&"unlock", -2.0)


func _on_finish_reached(pad: FinishPad) -> void:
	if _finished or not _running:
		return
	if pad.locked:
		var left := _builder.gems.size() - _gems_collected
		_hud.show_tip("%d gem%s still to find." % [left, "" if left == 1 else "s"])
		return
	_finished = true
	_running = false
	_marble.control_enabled = false
	# Heavy damping lets the marble settle on the pad instead of rolling off it.
	_marble.linear_damp = 4.0
	_marble.angular_damp = 4.0
	_clear_effects()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Audio.play(&"finish")
	_hud.flash(Color(1, 1, 1, 0.35))
	_bursts.burst(pad.global_position + Vector3.UP, FinishPad.OPEN_COLOR)
	var outcome := GameState.complete_level(_level, _time, _builder.gems.size())
	await get_tree().create_timer(FINISH_HOLD_SECONDS).timeout
	if not is_inside_tree():
		return
	_results.present(_level, _time, outcome,
		GameState.current_level + 1 < LevelCatalog.count())


func _on_next_pressed() -> void:
	SceneManager.play_level(GameState.current_level + 1)


# --- Falling and checkpoints ------------------------------------------------


func _on_checkpoint_reached(checkpoint: Checkpoint) -> void:
	for other in _builder.checkpoints:
		other.active = other == checkpoint
	_respawn_position = checkpoint.spawn_position()
	Audio.play(&"checkpoint", -4.0)


func _on_hazard_entered(_zone: TriggerZone) -> void:
	if _running:
		_respawn()


## Puts the marble back at the last checkpoint. The clock keeps running: a fall
## costs time, not the attempt.
func _respawn() -> void:
	_marble.teleport(_respawn_position)
	_camera.add_trauma(0.6)
	_hud.flash(Color(1.0, 0.3, 0.25, 0.4))
	Audio.play(&"crash", -4.0)
	# Wait for the teleport to land before the camera jumps to it.
	await get_tree().physics_frame
	await get_tree().physics_frame
	_camera.snap()


func _on_tip_entered(zone: TriggerZone) -> void:
	_hud.show_tip(zone.text)


# --- Power-ups --------------------------------------------------------------


func _on_pickup_taken(pickup: PowerUpPickup) -> void:
	var kind := pickup.kind
	_bursts.burst(pickup.global_position + Vector3.UP, PowerUps.color(kind))
	Audio.play(&"power_up")
	if not _seen_kinds.has(kind):
		_seen_kinds[kind] = true
		_hud.show_tip("%s: %s" % [PowerUps.label(kind), PowerUps.hint(kind)])
	if PowerUps.is_instant(kind):
		_start_effect(kind)
		return
	_held = kind
	_hud.set_power_up(kind)


func _use_power_up() -> void:
	if _held == EMPTY or not _running:
		return
	var kind := _held as PowerUps.Kind
	_held = EMPTY
	_hud.set_power_up(EMPTY)
	_bursts.burst(_marble.global_position, PowerUps.color(kind))
	match kind:
		PowerUps.Kind.SUPER_JUMP:
			_marble.launch(super_jump_speed)
			Audio.play(&"bounce", -2.0)
		PowerUps.Kind.BOOST:
			# Along the held direction if there is one, otherwise the view.
			var heading := _marble.wish_direction()
			if heading.length_squared() < 0.01:
				heading = Basis(Vector3.UP, _marble.steer_yaw) * Vector3.FORWARD
			_marble.boost(heading, boost_speed)
			Audio.play(&"boost", -2.0)
		_:
			_start_effect(kind)
			Audio.play(&"power_up", -4.0)


func _start_effect(kind: PowerUps.Kind) -> void:
	_effects[kind] = PowerUps.duration(kind)
	if kind == PowerUps.Kind.FEATHER:
		_marble.gravity_scale = feather_gravity


func _end_effect(kind: int) -> void:
	_effects.erase(kind)
	if kind == PowerUps.Kind.FEATHER:
		_marble.gravity_scale = 1.0


func _tick_effects(delta: float) -> void:
	# keys() returns a copy, so erasing inside the loop is safe.
	for kind: int in _effects.keys():
		_effects[kind] -= delta
		if _effects[kind] <= 0.0:
			_end_effect(kind)
			Audio.play(&"power_down", -8.0)


func _clear_effects() -> void:
	for kind: int in _effects.keys():
		_end_effect(kind)


func _pull_gems(delta: float) -> void:
	var target := _marble.global_position - Vector3.UP * Gem.HOVER
	for gem in _builder.gems:
		if gem.taken:
			continue
		var offset := target - gem.global_position
		if offset.length() < magnet_radius:
			gem.global_position += offset.limit_length(magnet_pull * delta)


# --- Feel -------------------------------------------------------------------


func _on_marble_jumped() -> void:
	Audio.play(&"jump", -6.0, 0.05)


func _on_marble_landed(impact: float) -> void:
	if impact < 3.0:
		return
	_camera.add_trauma(clampf(impact / 40.0, 0.05, 0.45))
	Audio.play(&"land", clampf(-14.0 + impact, -14.0, -2.0), 0.05)
