# Adding an Obstacle

No code is involved. An obstacle is a scene plus a spawn entry.

## 1. Build the scene

Create `obstacles/<name>.tscn` with an **`Area3D` root** in the `obstacle`
group:

```
collision_layer = 4      # the "obstacle" layer
collision_mask  = 0      # obstacles never detect; the player detects them
monitoring      = false
```

Give it a `MeshInstance3D` and a `CollisionShape3D`. Point the mesh at a shared
material in `resources/materials/` rather than adding a new sub-resource, so
the biome system can re-tint it.

### Geometry rules

A prop spanning `n` lanes is `2 + 5 * (n - 1)` units wide, and grows along **+X**
from its own lane. So its collision box is centred at `width / 2 - 1`:

| Lanes | Width | Collision centre X |
| ----- | ----- | ------------------ |
| 1     | 2     | 0                  |
| 2     | 7     | 2.5                |
| 3     | 12    | 5                  |

### Height decides whether it can be jumped

Nothing marks an obstacle jumpable. The marble's hitbox is a 0.75 sphere at
y = 1.4, and the jump apex adds about 0.95, so the hitbox bottom peaks near
y = 1.6:

- **Up to ~1.3 units tall** — clearable. Rocks and logs sit here.
- **2 units and over** — solid. Bushes, trees and crystals sit here.

Changing `jump_velocity` or `gravity` on the marble moves that line, so check
both bands still behave if you touch them.

## 2. Add a spawn entry

Create `resources/spawns/<name>.tres`:

```
[gd_resource type="Resource" script_class="SpawnEntry" load_steps=3 format=3]

[ext_resource type="Script" path="res://game/spawn_entry.gd" id="1_script"]
[ext_resource type="PackedScene" path="res://obstacles/<name>.tscn" id="2_scene"]

[resource]
script = ExtResource("1_script")
scene = ExtResource("2_scene")
lane_width = 1
weight = 1.5
```

`weight` is relative, not a percentage: a weight of 3 is picked three times as
often as a weight of 1.

## 3. Register it

Add the entry to the `obstacles` array on the **Track** node in
`game/game.tscn`. That is the whole job — pooling, movement, recycling and
collision all come for free.

## Collectibles and power-ups

Same pattern, different layer and group:

| Kind        | Layer | Group         | Root                             |
| ----------- | ----- | ------------- | -------------------------------- |
| Obstacle    | 4     | `obstacle`    | `Area3D`                         |
| Collectible | 8     | `collectible` | `Area3D`                         |
| Power-up    | 16    | `powerup`     | `Area3D` with `PowerUpPickup`    |

Power-ups go in the Track's `power_ups` array instead, and spawn in the
collectible slot, so picking one up never costs the player a safe lane.
