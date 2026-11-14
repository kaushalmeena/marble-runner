class_name Biome
extends Resource
## A palette for a level.
##
## Biomes only carry colour. Nothing about geometry or difficulty changes with
## them, so a new one is a single resource file and no code.

@export var biome_name: String = "Meadow"

@export_group("Ground")
@export var ground_color: Color = Color(0.42, 0.62, 0.35)
@export var stripe_color: Color = Color(0.12, 0.26, 0.13, 0.3)

@export_group("Props")
@export var foliage_color: Color = Color(0.16, 0.55, 0.28)
@export var bark_color: Color = Color(0.45, 0.28, 0.15)
@export var rock_color: Color = Color(0.52, 0.54, 0.57)

@export_group("Sky")
@export var fog_color: Color = Color(0.52, 0.68, 0.47)
@export var sky_top_color: Color = Color(0.2, 0.5, 0.88)
@export var sky_horizon_color: Color = Color(0.7, 0.85, 0.89)
@export var sky_ground_color: Color = Color(0.46, 0.64, 0.4)
@export var sun_color: Color = Color(1.0, 0.97, 0.9)


## Tints a sky, its fog and a sun to this palette. The environment is expected
## to be a private copy: this writes to it.
func apply(environment: Environment, sun: DirectionalLight3D) -> void:
	if sun != null:
		sun.light_color = sun_color
	if environment == null:
		return
	# The levels float, so there is no ground to meet the horizon. The lower
	# half of the sky fades into the haze colour instead, which reads as depth.
	var haze := sky_horizon_color.lerp(fog_color, 0.35)
	environment.fog_light_color = haze
	if environment.sky == null:
		return
	var sky := environment.sky.sky_material as ProceduralSkyMaterial
	if sky == null:
		return
	sky.sky_top_color = sky_top_color
	sky.sky_horizon_color = sky_horizon_color
	sky.ground_horizon_color = haze
	sky.ground_bottom_color = sky_top_color.lerp(fog_color, 0.5).darkened(0.25)
