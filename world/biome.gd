class_name Biome
extends Resource
## A palette for one stretch of the track.
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
