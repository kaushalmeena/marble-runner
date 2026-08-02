class_name Track
extends Node3D
## Scrolls, spawns and recycles everything that moves toward the player.
##
## Every prop is a plain [Area3D] scene with no script attached: this node owns
## their movement and their lifetime. Advancing them from one tight loop here is
## cheaper than giving each prop its own [code]_physics_process[/code] (which is
## what the Godot 3 version did, with a full [code]move_and_slide[/code] per
## prop), and it makes pooling possible so a long run stops churning nodes.

## Local Z where props appear. This sits beyond the environment's
## fog_depth_end, so props fade in out of the haze instead of popping into
## existence on the horizon.
const SPAWN_Z := -95.0
## Local Z past the camera where props are recycled.
const DESPAWN_Z := 25.0
## Parking spot for pooled props, safely off-screen and out of the play volume.
const POOL_PARK_POSITION := Vector3(0.0, -100.0, 0.0)

const GROUP_COLLECTIBLE := &"collectible"
const GROUP_OBSTACLE := &"obstacle"

## A collectible reached the despawn line without being picked up.
signal collectible_missed

## Per-prop state, kept as metadata so the pool can stay a plain array.
const META_LANE_X := &"lane_x"
const META_DRIFT := &"drift"
const META_DRIFT_PERIOD := &"drift_period"
const META_DRIFT_PHASE := &"drift_phase"

## Lane centres along X. The player is handed this same array, so the two can
## never disagree about where a lane is.
@export var lanes: PackedFloat32Array = PackedFloat32Array([-10.0, -5.0, 0.0, 5.0, 10.0])
## Weighted table of obstacles. Re-balance from the inspector, no code needed.
@export var obstacles: Array[SpawnEntry] = []
## Spawned between obstacles.
@export var collectible: PackedScene
## Weighted table of power-ups, spawned in place of the occasional collectible.
@export var power_ups: Array[SpawnEntry] = []
## Chance that a collectible slot yields a power-up instead.
@export_range(0.0, 1.0, 0.01) var power_up_chance: float = 0.14
## Props instantiated up front per entry, so the first spawns cause no hitch.
@export_range(0, 8, 1) var prewarm_per_entry: int = 2
## Whether the track scrolls as soon as it is ready. The game clears this so
## nothing moves until the countdown finishes.
@export var autostart: bool = true

@export_group("Curve")
## Ground material whose shader draws the bend. The track and the props must
## use the same curve or props would float off the road.
@export var ground_material: ShaderMaterial
## Sideways reach of the curve once it has fully ramped in, in units.
@export var max_curve_amplitude: float = 7.5
## Units travelled before the curve reaches full strength.
@export var curve_ramp_distance: float = 600.0
## Length of one full bend, in units. Longer is a lazier road.
@export var curve_wavelength: float = 240.0

@export_group("Difficulty")
## Scroll speed at the start of a run, in units/second.
@export var base_speed: float = 12.0
## Hard ceiling on scroll speed. Without one the old exponential ramp eventually
## moved props further than their own depth per frame and they passed straight
## through the player.
@export var max_speed: float = 42.0
## Units/second of scroll speed gained per unit travelled.
@export var speed_ramp: float = 0.012
## Distance between spawns at the start of a run.
@export var base_spawn_gap: float = 26.0
## Distance between spawns once the track is at its densest.
@export var min_spawn_gap: float = 14.0
## Distance travelled before the spawn gap reaches [member min_spawn_gap].
@export var gap_tighten_distance: float = 1200.0

## Multiplier applied to the scroll speed, driven by the slow-mo power-up.
var speed_scale: float = 1.0
## Current scroll speed, in units/second, after [member speed_scale].
var speed: float = 0.0
## Total distance travelled this run, in units.
var distance: float = 0.0

var _running: bool = false
var _active: Array[Area3D] = []
var _pool: Dictionary[String, Array] = {}
var _distance_since_spawn: float = 0.0
var _elapsed: float = 0.0
var _curve_phase: float = 0.0
var _curve_amplitude: float = 0.0
var _lane_spacing: float = 5.0
var _magnet_target: Node3D = null
var _magnet_radius: float = 0.0
var _magnet_pull: float = 0.0
var _collectible_is_next: bool = false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	speed = base_speed
	if lanes.size() > 1:
		_lane_spacing = absf(lanes[1] - lanes[0])
	_push_curve_to_shader()
	_prewarm()
	_running = autostart


func _physics_process(delta: float) -> void:
	if not _running:
		return
	_elapsed += delta
	_update_speed()
	var step := speed * delta
	distance += step
	_update_curve(step)
	_advance_props(step, delta)
	_update_spawning(step)


## Starts pulling collectibles toward [param target] while the magnet runs.
func set_magnet(target: Node3D, radius: float, pull: float) -> void:
	_magnet_target = target
	_magnet_radius = radius
	_magnet_pull = pull


func clear_magnet() -> void:
	_magnet_target = null


## Sideways offset of the road at a given depth. Zero at the player's depth, so
## a prop always arrives on its true lane centre no matter how hard the road is
## winding further out.
func bend_at(z: float) -> float:
	if _curve_amplitude <= 0.0:
		return 0.0
	var k := TAU / maxf(1.0, curve_wavelength)
	return _curve_amplitude * (sin(_curve_phase + (z - DESPAWN_Z) * k) - sin(_curve_phase))


## Recycles everything currently on the track. Used by the revive, so the player
## does not come back inside whatever just killed them.
func clear_props(obstacles_only: bool = false) -> void:
	for i in range(_active.size() - 1, -1, -1):
		var prop := _active[i]
		if obstacles_only and not prop.is_in_group(GROUP_OBSTACLE):
			continue
		_active.remove_at(i)
		_release(prop)


## Starts scrolling. Called once the countdown is over.
func start() -> void:
	_running = true


## Freezes the track. Called when the run ends so the world stops under the
## player instead of sliding on during the death transition.
func stop() -> void:
	_running = false


## Fraction of the way from [member base_speed] to [member max_speed], for the
## HUD speed meter.
func speed_ratio() -> float:
	var span := max_speed - base_speed
	if span <= 0.0:
		return 1.0
	return clampf((speed - base_speed) / span, 0.0, 1.0)


## Returns a prop to the pool early. Used when the player collects a fruit
## before it has scrolled past the despawn line.
func recycle(prop: Area3D) -> void:
	var index := _active.find(prop)
	if index == -1:
		return
	_active.remove_at(index)
	_release(prop)


## The bend pattern is anchored to the world, so as the world scrolls past by
## `step` the phase has to walk back by the same amount for the curve to travel
## with the props rather than sliding through them.
func _update_curve(step: float) -> void:
	if curve_ramp_distance > 0.0:
		_curve_amplitude = max_curve_amplitude * clampf(
			distance / curve_ramp_distance, 0.0, 1.0)
	else:
		_curve_amplitude = max_curve_amplitude
	_curve_phase -= step * TAU / maxf(1.0, curve_wavelength)
	_curve_phase = fposmod(_curve_phase, TAU)
	_push_curve_to_shader()


func _push_curve_to_shader() -> void:
	if ground_material == null:
		return
	ground_material.set_shader_parameter(&"curve_amplitude", _curve_amplitude)
	ground_material.set_shader_parameter(&"curve_wavelength", curve_wavelength)
	ground_material.set_shader_parameter(&"curve_phase", _curve_phase)
	ground_material.set_shader_parameter(&"curve_pivot_z", DESPAWN_Z)
	ground_material.set_shader_parameter(&"lane_spacing", _lane_spacing)


func _update_speed() -> void:
	speed = minf(max_speed, base_speed + distance * speed_ramp) * speed_scale


func _advance_props(step: float, delta: float) -> void:
	# Iterate backwards so removing a prop cannot skip its neighbour.
	for i in range(_active.size() - 1, -1, -1):
		var prop := _active[i]
		prop.position.z += step
		if _magnet_target != null and prop.is_in_group(GROUP_COLLECTIBLE):
			_apply_magnet(prop, delta)
		else:
			prop.position.x = _prop_x(prop)
		if prop.position.z > DESPAWN_Z:
			_active.remove_at(i)
			# Reaching the despawn line means the player never picked it up.
			if prop.is_in_group(GROUP_COLLECTIBLE):
				collectible_missed.emit()
			_release(prop)


func _update_spawning(step: float) -> void:
	_distance_since_spawn += step
	var gap := _current_spawn_gap()
	if _distance_since_spawn < gap:
		return
	# Subtract rather than reset, so the spacing does not drift at high speed.
	_distance_since_spawn -= gap
	if _collectible_is_next:
		_spawn_collectible()
	else:
		_spawn_obstacle()
	_collectible_is_next = not _collectible_is_next


## Spawning by distance rather than on a timer keeps obstacle spacing constant
## as the speed climbs. The old version shrank the timer *and* raised the speed,
## so density spiked unpredictably.
func _current_spawn_gap() -> float:
	if gap_tighten_distance <= 0.0:
		return min_spawn_gap
	var t := clampf(distance / gap_tighten_distance, 0.0, 1.0)
	return lerpf(base_spawn_gap, min_spawn_gap, t)


func _spawn_obstacle() -> void:
	var entry := _pick_weighted(obstacles)
	if entry == null:
		return
	_place(entry.scene, entry.lane_width, entry)


func _spawn_collectible() -> void:
	# Power-ups ride in the collectible slot rather than the obstacle slot, so
	# picking one up never costs the player a safe lane.
	if not power_ups.is_empty() and _rng.randf() < power_up_chance:
		var entry := _pick_weighted(power_ups)
		if entry != null:
			_place(entry.scene, entry.lane_width, entry)
			return
	if collectible == null:
		return
	_place(collectible, 1)


func _place(scene: PackedScene, lane_width: int, entry: SpawnEntry = null) -> void:
	var prop := _acquire(scene)
	if prop == null:
		return
	prop.set_meta(META_LANE_X, _random_lane_x(lane_width))
	prop.set_meta(META_DRIFT, 0.0 if entry == null else entry.drift_lanes)
	prop.set_meta(META_DRIFT_PERIOD, 3.0 if entry == null else entry.drift_period)
	# A per-prop phase stops a row of drifters swinging in lockstep.
	prop.set_meta(META_DRIFT_PHASE, _rng.randf() * TAU)
	prop.position = Vector3(0.0, 0.0, SPAWN_Z)
	prop.position.x = _prop_x(prop)
	_active.append(prop)


## Where a prop sits this frame: its lane, plus any drift, plus the road bend.
## Drift is real gameplay and is clamped to the track; the bend is not, and
## cancels out by the time the prop reaches the player.
func _prop_x(prop: Area3D) -> float:
	var lane_x: float = prop.get_meta(META_LANE_X, 0.0)
	var drift: float = prop.get_meta(META_DRIFT, 0.0)
	if drift > 0.0:
		var period: float = maxf(0.1, prop.get_meta(META_DRIFT_PERIOD, 3.0))
		var phase: float = prop.get_meta(META_DRIFT_PHASE, 0.0)
		lane_x += drift * _lane_spacing * sin(TAU * _elapsed / period + phase)
		lane_x = clampf(lane_x, lanes[0], lanes[lanes.size() - 1])
	return lane_x + bend_at(prop.position.z)


## Picks an entry proportionally to its weight.
func _pick_weighted(entries: Array[SpawnEntry]) -> SpawnEntry:
	var total := 0.0
	for entry in entries:
		if entry != null and entry.scene != null:
			total += maxf(0.0, entry.weight)
	if total <= 0.0:
		return null
	var roll := _rng.randf() * total
	for entry in entries:
		if entry == null or entry.scene == null:
			continue
		roll -= maxf(0.0, entry.weight)
		if roll <= 0.0:
			return entry
	return null


## Drags nearby collectibles toward the magnet target.
func _apply_magnet(prop: Area3D, delta: float) -> void:
	var target := _magnet_target.global_position
	var here := prop.global_position
	if here.distance_squared_to(target) > _magnet_radius * _magnet_radius:
		return
	prop.global_position = here.move_toward(target, _magnet_pull * delta)


## A prop [param lane_width] lanes wide extends along +X from the lane it is
## given, so its lane is drawn from the lanes that leave room for it.
func _random_lane_x(lane_width: int) -> float:
	var highest_index := maxi(0, lanes.size() - lane_width)
	return lanes[_rng.randi_range(0, highest_index)]


func _prewarm() -> void:
	if prewarm_per_entry <= 0:
		return
	var scenes: Array[PackedScene] = []
	for entry in obstacles + power_ups:
		if entry != null and entry.scene != null:
			scenes.append(entry.scene)
	if collectible != null:
		scenes.append(collectible)
	for scene in scenes:
		for _i in prewarm_per_entry:
			var prop := _acquire(scene)
			if prop != null:
				_release(prop)


func _acquire(scene: PackedScene) -> Area3D:
	var bucket: Array = _pool.get(scene.resource_path, [])
	var prop: Area3D
	if bucket.is_empty():
		prop = scene.instantiate() as Area3D
		if prop == null:
			push_error("Spawnable scene %s must have an Area3D root." % scene.resource_path)
			return null
		add_child(prop)
	else:
		prop = bucket.pop_back()
	prop.visible = true
	return prop


func _release(prop: Area3D) -> void:
	# Parking the prop far below the track is what takes it out of detection
	# range; hiding it takes it out of the render pass. Toggling `monitorable`
	# would be redundant, and is outright forbidden here: _release runs inside
	# the player's area_entered callback when a fruit is collected, and the
	# physics server is locked for the duration of that signal.
	prop.visible = false
	prop.position = POOL_PARK_POSITION
	var key := prop.scene_file_path
	if not _pool.has(key):
		_pool[key] = []
	_pool[key].append(prop)
