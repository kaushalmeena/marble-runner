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

## Relative likelihood of being picked. A weight of 3.0 is chosen three times as
## often as a weight of 1.0.
@export_range(0.0, 10.0, 0.1, "or_greater") var weight: float = 1.0
