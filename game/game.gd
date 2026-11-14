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
## A guard is popped when the marble is at least this far above it and falling
## at least this fast, and the marble bounces off at the speed below.
const STOMP_HEIGHT := 0.25
const STOMP_SPEED := 1.0
const STOMP_BOUNCE := 8.0

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
@onready var _cheats: Cheats = $Cheats

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
var _keys: int = 0
## Set by the first cheat that touches the run. A cheated run is not recorded.
var _cheated: bool = false
## Gravity multiplier for this run: the level's own, unless a cheat changed it.
var _base_gravity: float = 1.0
var _endless_air_jumps: bool = false


func _ready() -> void:
	_level = LevelCatalog.at(GameState.current_level)
	# A private copy: the palette is written into it, and the shared resource
	# must not carry one level's colours into the next.
	var environment: Environment = ENVIRONMENT.duplicate(true)
	_level.biome.apply(environment, _sun)
	_world.environment = environment

	_builder = LevelBuilder.new(_level_root, _level.biome)
	_level.build(_builder)
	_connect_level()

	_respawn_position = _builder.start_position
	_marble.global_position = _respawn_position
	_base_gravity = _level.gravity_scale
	_marble.gravity_scale = _base_gravity
	_marble.landed.connect(_on_marble_landed)
	_marble.jumped.connect(_on_marble_jumped)
	_camera.follow(_marble, _builder.start_yaw)

	_hud.setup(GameState.current_level + 1, _level, _builder.gems.size(),
		GameState.best_time(_level))
	_results.next_pressed.connect(_on_next_pressed)
	_results.retry_pressed.connect(SceneManager.restart_level)
	_results.levels_pressed.connect(SceneManager.goto_level_select)
	_cheats.entered.connect(_on_cheat_entered)
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
	for enemy in _builder.enemies:
		enemy.target = _marble
		enemy.touched.connect(_on_enemy_touched)
	for portal in _builder.portals:
		portal.used.connect(_on_portal_used)
	for key in _builder.keys:
		key.collected.connect(_on_key_collected)
	for gate in _builder.gates:
		gate.touched.connect(_on_gate_touched)
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
	_hud.set_underwater(_marble.in_water)
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
	# A cheated run finishes the level but leaves no trace: no time, no stars,
	# no coins, and it does not unlock the next level.
	var outcome := GameState.unrecorded_outcome(_level) if _cheated \
		else GameState.complete_level(_level, _time, _builder.gems.size())
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
	if _running and not _effects.has(PowerUps.Kind.SHIELD):
		_respawn()


## A guard was touched. Landing on it from above, or being shielded, pops it;
## anything else is a trip back to the checkpoint.
func _on_enemy_touched(enemy: Enemy) -> void:
	if not _running:
		return
	var from_above := _marble.global_position.y > enemy.global_position.y + STOMP_HEIGHT \
		and _marble.linear_velocity.y < -STOMP_SPEED
	if _effects.has(PowerUps.Kind.SHIELD) or from_above:
		enemy.defeat()
		_bursts.burst(enemy.global_position + Vector3.UP * Enemy.RADIUS, Enemy.BODY_COLOR)
		Audio.play(&"bumper", -2.0, 0.05, 0.8)
		_camera.add_trauma(0.25)
		if from_above:
			_marble.launch(STOMP_BOUNCE)
		return
	_respawn()


# --- Portals, keys and gates ------------------------------------------------


## Turns the view to face the way the marble was thrown out, then catches up.
func _on_portal_used(exit: Portal) -> void:
	var out := exit.exit_direction()
	_camera.yaw = atan2(-out.x, -out.z)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_camera.snap()


func _on_key_collected(key: GateKey) -> void:
	_keys += 1
	_hud.set_keys(_keys)
	_bursts.burst(key.global_position + Vector3.UP, GateKey.COLOR)
	Audio.play(&"checkpoint", -2.0, 0.0, 1.3)


func _on_gate_touched(gate: Gate) -> void:
	if _keys <= 0:
		_hud.show_tip("Locked. There is a key somewhere.")
		return
	_keys -= 1
	_hud.set_keys(_keys)
	gate.open()
	Audio.play(&"unlock", -2.0)


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
	match kind:
		PowerUps.Kind.FEATHER:
			_marble.gravity_scale = _base_gravity * feather_gravity
		PowerUps.Kind.SHIELD:
			_marble.set_shielded(true)
		PowerUps.Kind.DOUBLE_JUMP:
			_marble.air_jumps = 1


func _end_effect(kind: int) -> void:
	_effects.erase(kind)
	match kind:
		PowerUps.Kind.FEATHER:
			_marble.gravity_scale = _base_gravity
		PowerUps.Kind.SHIELD:
			_marble.set_shielded(false)
		PowerUps.Kind.DOUBLE_JUMP:
			_marble.air_jumps = 99 if _endless_air_jumps else 0


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


# --- Cheats -----------------------------------------------------------------


func _on_cheat_entered(code: StringName) -> void:
	if _finished:
		return
	if Cheats.voids_run(code):
		_cheated = true
		_hud.mark_cheated()
	_hud.show_banner("CHEAT ACTIVATED", 0.9, Color(1.0, 0.85, 0.3))
	_hud.show_tip(Cheats.CODES[code])
	Audio.play(&"unlock", -2.0, 0.0, 1.2)
	match code:
		&"MOONBOOTS":
			_base_gravity = 0.35
			_marble.gravity_scale = _base_gravity
		&"BUBBLE":
			_start_effect(PowerUps.Kind.SHIELD)
			_effects[PowerUps.Kind.SHIELD] = 60.0
		&"SKYHOOK":
			_endless_air_jumps = true
			_marble.air_jumps = 99
		&"ZOOMZOOM":
			_marble.max_speed *= 1.6
			_marble.roll_torque *= 1.5
		&"TICKTOCK":
			_effects[PowerUps.Kind.STOPWATCH] = 60.0
		&"ALLGEMS":
			for gem in _builder.gems:
				if not gem.taken:
					gem.collect()
		&"SKELETONKEY":
			_keys += 3
			_hud.set_keys(_keys)
		&"BOWLING":
			for enemy in _builder.enemies:
				enemy.defeat()
		&"TOOLKIT":
			_held = (_held + 1) % PowerUps.Kind.size()
			if PowerUps.is_instant(_held as PowerUps.Kind):
				_held = (_held + 1) % PowerUps.Kind.size()
			_hud.set_power_up(_held)
		&"GOLDMINE":
			GameState.coins += 500
			GameState.save_progress()
		&"ALLACCESS":
			GameState.unlock_all()


# --- Feel -------------------------------------------------------------------


func _on_marble_jumped() -> void:
	Audio.play(&"jump", -6.0, 0.05)


func _on_marble_landed(impact: float) -> void:
	if impact < 3.0:
		return
	_camera.add_trauma(clampf(impact / 40.0, 0.05, 0.45))
	Audio.play(&"land", clampf(-14.0 + impact, -14.0, -2.0), 0.05)
