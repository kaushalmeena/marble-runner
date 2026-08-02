class_name SpawnEntry
extends Resource
## One row of the [Track] spawn table.
##
## Replaces the nested "[length, [scenes]]" arrays the Godot 3 version used, so
## new obstacles can be added and re-balanced from the inspector without editing
## any code.

## Scene to instantiate. Its root must be an [Area3D].
@export var scene: PackedScene

## How many adjacent lanes the obstacle covers, counting from its own lane
## outwards along +X. Used so a wide obstacle never spawns hanging off the track.
@export_range(1, 5, 1) var lane_width: int = 1

## How many lanes either side the prop sweeps while it approaches. Zero holds
## it in its lane. Unlike the road bend, drift does not cancel out at the
## player, so a drifting prop genuinely has to be read rather than memorised.
@export_range(0.0, 2.0, 0.1) var drift_lanes: float = 0.0

## Seconds for one full sweep.
@export_range(0.5, 8.0, 0.1) var drift_period: float = 3.0

## Relative likelihood of being picked. A weight of 3.0 is chosen three times as
## often as a weight of 1.0.
@export_range(0.0, 10.0, 0.1, "or_greater") var weight: float = 1.0
