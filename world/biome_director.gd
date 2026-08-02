class_name BiomeDirector
extends Node
## Cross-fades the world palette as the run gets longer.
##
## The colours live on the shared material and environment resources, so tinting
## them here re-skins every prop on the track at once without touching a single
## node. Nothing is written back to disk: these are the runtime copies.
##
## Blending is continuous rather than switching at a boundary, so the world
## drifts from one biome into the next instead of snapping.

## Biomes are cycled in order, and the list wraps, so a long enough run loops
## back round to the first.
@export var biomes: Array[Biome] = []
## Distance covered in each biome before the next one takes over.
@export var distance_per_biome: float = 900.0
## Fraction of a biome's length spent blending into the next.
@export_range(0.05, 1.0, 0.05) var blend_fraction: float = 0.35

@export_group("Targets")
@export var ground_material: StandardMaterial3D
@export var stripe_material: StandardMaterial3D
@export var foliage_material: StandardMaterial3D
@export var bark_material: StandardMaterial3D
@export var rock_material: StandardMaterial3D
@export var environment: Environment
## Resolved from a path rather than an exported node reference, which did not
## survive the round trip through the scene file.
@export var sun_path: NodePath

var sun: DirectionalLight3D = null

var _track: Track = null
var _sky_material: ProceduralSkyMaterial = null
var _last_applied: float = -1000.0


func _ready() -> void:
	sun = get_node_or_null(sun_path) as DirectionalLight3D
	if environment != null and environment.sky != null:
		_sky_material = environment.sky.sky_material as ProceduralSkyMaterial
	set_process(false)


## Gives the director the track whose distance drives the blend.
func bind_track(track: Track) -> void:
	_track = track
	set_process(track != null and not biomes.is_empty())
	if _track != null:
		_apply(0.0)


func _process(_delta: float) -> void:
	_apply(_track.distance)


## Returns the biome the run is currently in, for the HUD or debugging.
func current_biome() -> Biome:
	if biomes.is_empty() or _track == null:
		return null
	return biomes[_biome_index(_track.distance)]


func _apply(distance: float) -> void:
	# Re-tinting every frame would touch a dozen resources for no visible gain;
	# a metre of travel is far finer than the eye can see in a colour ramp.
	if absf(distance - _last_applied) < 1.0:
		return
	_last_applied = distance

	var index := _biome_index(distance)
	var from := biomes[index]
	var to := biomes[(index + 1) % biomes.size()]
	var weight := _blend_weight(distance)

	if ground_material != null:
		ground_material.albedo_color = from.ground_color.lerp(to.ground_color, weight)
	if stripe_material != null:
		stripe_material.albedo_color = from.stripe_color.lerp(to.stripe_color, weight)
	if foliage_material != null:
		foliage_material.albedo_color = from.foliage_color.lerp(to.foliage_color, weight)
	if bark_material != null:
		bark_material.albedo_color = from.bark_color.lerp(to.bark_color, weight)
	if rock_material != null:
		rock_material.albedo_color = from.rock_color.lerp(to.rock_color, weight)
	if sun != null:
		sun.light_color = from.sun_color.lerp(to.sun_color, weight)

	var fog := from.fog_color.lerp(to.fog_color, weight)
	if environment != null:
		environment.fog_light_color = fog
	if _sky_material != null:
		_sky_material.sky_top_color = from.sky_top_color.lerp(to.sky_top_color, weight)
		_sky_material.sky_horizon_color = from.sky_horizon_color.lerp(
			to.sky_horizon_color, weight)
		# The sky's ground half is held to the fog colour so distant track melts
		# into the horizon with no seam, whatever the biome.
		_sky_material.ground_horizon_color = fog
		_sky_material.ground_bottom_color = from.sky_ground_color.lerp(
			to.sky_ground_color, weight)


func _biome_index(distance: float) -> int:
	if distance_per_biome <= 0.0:
		return 0
	return int(distance / distance_per_biome) % biomes.size()


## 0 for most of a biome, ramping to 1 across the tail end of it.
func _blend_weight(distance: float) -> float:
	if distance_per_biome <= 0.0:
		return 0.0
	var progress := fposmod(distance, distance_per_biome) / distance_per_biome
	var blend_start := 1.0 - blend_fraction
	if progress <= blend_start:
		return 0.0
	return smoothstep(0.0, 1.0, (progress - blend_start) / blend_fraction)
