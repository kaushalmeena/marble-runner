extends Node3D
## Gameplay root. Builds the level, then referees it: the clock, the gems, the
## running power-ups, falls and the finish.
##
## Everything here is a connection or a hand-off. Gimmicks act on the marble by
## themselves; this script only hears about the things that change the state of
## the run. What each power-up actually *does* is decided here, next to the
## objects it affects.

const ENVIRONMENT := preload("res://resources/environments/day_sky.tres")
## Pause between crossing the finish and the results card, so the moment lands.
const FINISH_HOLD_SECONDS := 0.9
## A guard is popped when the marble is at least this far above it and falling
## at least this fast, and the marble bounces off at the speed below.
const STOMP_HEIGHT := 0.25
const STOMP_SPEED := 1.0
const STOMP_BOUNCE := 8.0

@export_group("Power-up tuning")
## Jump speed multiplier while super jump runs. At 1.85 a jump is about three
## and a half times as high.
@export var super_jump_scale: float = 1.85
## Top speed and torque multiplier while boost runs, and the shove on pickup.
@export var boost_scale: float = 1.6
@export var boost_kick: float = 16.0
## Gravity multiplier while the feather runs.
@export var feather_gravity: float = 0.3
## Top speed multiplier while slowed, and what being heavy does to jumps and
## to gravity.
@export var slow_scale: float = 0.45
@export var heavy_jump: float = 0.62
@export var heavy_gravity: float = 1.5
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
## Seconds left on each running effect, keyed by [enum PowerUps.Kind].
var _effects: Dictionary[int, float] = {}
var _seen_kinds: Dictionary[int, bool] = {}
var _keys: int = 0
## Set by the first cheat that touches the run. A cheated run is not recorded.
var _cheated: bool = false
## Gravity multiplier for this run: the level's own, unless a cheat changed it.
var _base_gravity: float = 1.0
var _endless_air_jumps: bool = false
var _speed_cheat: float = 1.0
## The marble's own tuning, read once, so effects scale it rather than drift it.
var _marble_jump_speed: float = 0.0
var _marble_max_speed: float = 0.0
var _marble_roll_torque: float = 0.0
## Night levels: the light the marble carries, and whether a flare is up.
var _lamp: OmniLight3D = null
var _lit: bool = true
var _light_tween: Tween
var _wind_streaks: CPUParticles3D = null


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
	_marble_jump_speed = _marble.jump_speed
	_marble_max_speed = _marble.max_speed
	_marble_roll_torque = _marble.roll_torque
	_marble.landed.connect(_on_marble_landed)
	_marble.jumped.connect(_on_marble_jumped)
	_camera.follow(_marble, _builder.start_yaw)

	if _level.dark:
		_build_night()
	if _level.wind != Vector3.ZERO:
		_build_wind()
	_hud.setup(GameState.current_level + 1, _level, _builder.gems.size(),
		GameState.best_time(_level))
	_apply_effects()
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
		enemy.shot_struck.connect(_on_hazard_entered.bind(null))
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
	if _lamp != null:
		_lamp.global_position = _marble.global_position + Vector3.UP * 1.8
	if _wind_streaks != null:
		_wind_streaks.global_position = _marble.global_position + Vector3.UP * 2.0 \
			- _level.wind.normalized() * 9.0
	for kind in Hud.EFFECT_KINDS:
		_hud.set_effect(kind, minf(1.0, _effects.get(kind, 0.0) / PowerUps.duration(kind)))


func _physics_process(delta: float) -> void:
	if not _running:
		return
	if not _effects.has(PowerUps.Kind.STOPWATCH):
		_time += delta
	_tick_effects(delta)
	if _effects.has(PowerUps.Kind.MAGNET):
		_pull_gems(delta)
	if _level.wind != Vector3.ZERO and not _marble.in_water \
			and not _effects.has(PowerUps.Kind.GRIP):
		_marble.apply_central_force(_level.wind * _marble.mass)
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


## Red blocks, lit beams and a sentry's shots all end the same way.
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


## A pickup takes effect the moment it is touched. Different power-ups run
## side by side; another of one already running adds its time on top.
func _on_pickup_taken(pickup: PowerUpPickup) -> void:
	var kind := pickup.kind
	_bursts.burst(pickup.global_position + Vector3.UP, PowerUps.color(kind))
	if PowerUps.is_ailment(kind):
		# A trap. The shield turns it away; otherwise it lands like a blow.
		if _effects.has(PowerUps.Kind.SHIELD):
			_hud.show_tip("Your shield soaked up the trap.")
			Audio.play(&"bumper", -6.0, 0.0, 1.3)
			return
		Audio.play(&"power_down", -2.0, 0.0, 0.8)
		_camera.add_trauma(0.35)
		_hud.flash(Color(PowerUps.color(kind), 0.3))
	else:
		Audio.play(&"power_up")
	if not _seen_kinds.has(kind):
		_seen_kinds[kind] = true
		_hud.show_tip("%s: %s" % [PowerUps.label(kind), PowerUps.hint(kind)])
	_start_effect(kind)
	if kind == PowerUps.Kind.BOOST:
		# A shove to go with the higher top speed, the way the marble is
		# already heading, or the way the view faces if it is standing still.
		var heading := _marble.linear_velocity
		heading.y = 0.0
		if heading.length_squared() < 1.0:
			heading = Basis(Vector3.UP, _marble.steer_yaw) * Vector3.FORWARD
		_marble.boost(heading, boost_kick)
		Audio.play(&"boost", -4.0)


## Starts an effect, or extends one that is already running. Stacked time is
## capped, so hoarding a respawning pickup cannot bank an effect for ever.
func _start_effect(kind: PowerUps.Kind, seconds: float = -1.0) -> void:
	var duration := PowerUps.duration(kind) if seconds < 0.0 else seconds
	var cap := maxf(duration, PowerUps.duration(kind) * PowerUps.MAX_STACK)
	_effects[kind] = minf(_effects.get(kind, 0.0) + duration, cap)
	_apply_effects()


func _end_effect(kind: int) -> void:
	_effects.erase(kind)
	_apply_effects()


## Sets everything a power-up can change on the marble from what is running
## now. Derived from scratch each time rather than added and removed, so two
## effects ending in either order can never leave a value stuck.
func _apply_effects() -> void:
	var has := func(kind: PowerUps.Kind) -> bool: return _effects.has(kind)
	var heavy: bool = has.call(PowerUps.Kind.HEAVY)
	_marble.gravity_scale = _base_gravity * (
		feather_gravity if has.call(PowerUps.Kind.FEATHER) else 1.0) * (
		heavy_gravity if heavy else 1.0)
	_marble.jump_speed = _marble_jump_speed * (
		super_jump_scale if has.call(PowerUps.Kind.SUPER_JUMP) else 1.0) * (
		heavy_jump if heavy else 1.0)
	var pace := _speed_cheat * (boost_scale if has.call(PowerUps.Kind.BOOST) else 1.0) * (
		slow_scale if has.call(PowerUps.Kind.SLOW) else 1.0)
	_marble.steer_flipped = has.call(PowerUps.Kind.DIZZY)
	_marble.sure_footed = has.call(PowerUps.Kind.GRIP)
	_set_lit(not _level.dark or has.call(PowerUps.Kind.FLARE))
	_marble.max_speed = _marble_max_speed * pace
	_marble.roll_torque = _marble_roll_torque * pace
	_marble.set_shielded(has.call(PowerUps.Kind.SHIELD))
	var air_jumps := 99 if _endless_air_jumps else (
		1 if has.call(PowerUps.Kind.DOUBLE_JUMP) else 0)
	# Only on a change: setting it refills the jump, which would otherwise
	# hand out a free one every time some other effect started or ended.
	if _marble.air_jumps != air_jumps:
		_marble.air_jumps = air_jumps
	_hud.set_environment(_environment_tags())


## Standing conditions of the level, for the HUD: things that are true the
## whole way through rather than for a few seconds.
func _environment_tags() -> PackedStringArray:
	var tags := PackedStringArray()
	if _base_gravity < 0.99:
		tags.append("LOW GRAVITY")
	elif _base_gravity > 1.01:
		tags.append("HIGH GRAVITY")
	if _level.wind != Vector3.ZERO:
		tags.append("WIND")
	if _level.dark:
		tags.append("DARK")
	if _builder.has_water:
		tags.append("WATER")
	if _speed_cheat > 1.0:
		tags.append("FAST")
	return tags


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


# --- Night and wind -----------------------------------------------------------


## Puts the level in the dark and gives the marble a light of its own.
func _build_night() -> void:
	_lamp = OmniLight3D.new()
	_lamp.light_color = Color(1.0, 0.93, 0.8)
	_lamp.light_energy = 2.4
	_lamp.omni_range = 13.0
	_lamp.omni_attenuation = 1.3
	# Held above the marble, not inside it: a light at the centre of a ball
	# lights everything but the ball.
	add_child(_lamp)
	_lit = true
	_set_lit(false, 0.0)


## Fades the world between night and lit. A flare is daylight for a while.
func _set_lit(lit: bool, seconds: float = 0.6) -> void:
	if lit == _lit or _lamp == null:
		return
	_lit = lit
	var environment := _world.environment
	var level := 1.0 if lit else 0.0
	if _light_tween != null:
		_light_tween.kill()
	if seconds <= 0.0:
		_sun.light_energy = lerpf(0.04, 0.75, level)
		environment.ambient_light_energy = lerpf(0.18, 1.0, level)
		environment.background_energy_multiplier = lerpf(0.16, 0.8, level)
		environment.fog_light_energy = lerpf(0.12, 0.8, level)
		return
	_light_tween = create_tween().set_parallel()
	_light_tween.tween_property(_sun, ^"light_energy", lerpf(0.04, 0.75, level), seconds)
	_light_tween.tween_property(environment, ^"ambient_light_energy",
		lerpf(0.18, 1.0, level), seconds)
	_light_tween.tween_property(environment, ^"background_energy_multiplier",
		lerpf(0.16, 0.8, level), seconds)
	_light_tween.tween_property(environment, ^"fog_light_energy", lerpf(0.12, 0.8, level), seconds)


## Streaks of air blowing past the marble, so the wind can be seen.
func _build_wind() -> void:
	var streaks := CPUParticles3D.new()
	streaks.amount = 36
	streaks.lifetime = 1.3
	streaks.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	streaks.emission_box_extents = Vector3(9.0, 3.0, 9.0)
	streaks.direction = _level.wind.normalized()
	streaks.spread = 3.0
	streaks.gravity = Vector3.ZERO
	streaks.initial_velocity_min = 13.0
	streaks.initial_velocity_max = 17.0
	streaks.particle_flag_align_y = true
	var streak := BoxMesh.new()
	streak.size = Vector3(0.04, 1.4, 0.04)
	streak.material = Mats.ghost(Color(0.9, 0.96, 1.0), 0.22)
	streaks.mesh = streak
	# Top level: the streaks blow through the world, not along with the marble.
	streaks.top_level = true
	add_child(streaks)
	_wind_streaks = streaks


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
		&"BUBBLE":
			_start_effect(PowerUps.Kind.SHIELD, 60.0)
		&"SKYHOOK":
			_endless_air_jumps = true
		&"ZOOMZOOM":
			_speed_cheat = 1.6
		&"TICKTOCK":
			_start_effect(PowerUps.Kind.STOPWATCH, 60.0)
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
			for kind: PowerUps.Kind in PowerUps.Kind.values():
				if not PowerUps.is_ailment(kind):
					_start_effect(kind)
		&"GOLDMINE":
			GameState.coins += 500
			GameState.save_progress()
		&"ALLACCESS":
			GameState.unlock_all()
	_apply_effects()


# --- Feel -------------------------------------------------------------------


func _on_marble_jumped() -> void:
	Audio.play(&"jump", -6.0, 0.05)


func _on_marble_landed(impact: float) -> void:
	if impact < 3.0:
		return
	_camera.add_trauma(clampf(impact / 40.0, 0.05, 0.45))
	Audio.play(&"land", clampf(-14.0 + impact, -14.0, -2.0), 0.05)
