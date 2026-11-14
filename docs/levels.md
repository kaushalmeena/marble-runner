# Levels

How to add a level, what the builder can place, and the numbers a level is
measured against.

## Adding a level

1. Create `levels/defs/my_level.gd`:

```gdscript
extends LevelDef


func _init() -> void:
	id = &"my_level"           # save-file key: never rename it afterwards
	title = "My Level"
	hint = "One line for the level card."
	biome = preload("res://resources/biomes/dusk.tres")
	gold_time = 20.0
	silver_time = 35.0


func build(b: LevelBuilder) -> void:
	b.start(Vector3(0, 0, 0))
	b.floor(0, -6, 8, 16)
	b.gem_line(Vector3(0, 0, -4), Vector3(0, 0, -10), 3)
	b.finish_at(Vector3(0, 0, -12))
```

2. Add it to `SCRIPTS` in `levels/level_catalog.gd`. Its position there is its
   place in the unlock order. The level select and the menus pick it up.

3. Play it to the end. Set the gold time near a clean run and the silver time
   around one and a half times that.

## Conventions the builder assumes

- **Forward is -Z.** A level starts near the origin and heads away from the
  camera. `+X` is right.
- **Gimmick positions are floor points.** Pass the spot it stands on; the
  builder lifts gems and pickups to hover height itself.
- **`floor()` takes the height of the walkable top**, not the box centre.
- **Leave no coplanar overlap.** Two floors at the same height should touch,
  not overlap, or their tops flicker.

## What can be placed

| Call | What it is |
| --- | --- |
| `floor`, `box`, `ramp`, `curved_ramp`, `wall` | Fixed geometry. `Surface.ICE` for ice, `Surface.WALL` for the second colour. |
| `mover` | A platform gliding between two points, parking at each end. |
| `crumble` | A tile that drops shortly after being touched, then regrows. |
| `start`, `finish_at`, `checkpoint` | Where the run begins, ends, and resumes after a fall. |
| `gem`, `gem_line`, `gem_ring` | Collectibles. All of them open the finish. |
| `power_up` | A pickup. Takes effect on touch and respawns a few seconds later. |
| `boost_pad`, `bounce_pad` | Fling the marble along the floor, or straight up. |
| `bumper`, `spinner` | A post that kicks back; a bar that sweeps round a hub. |
| `fan` | A column of rising air. The marble hovers halfway up it. |
| `hazard` | A red block that sends the marble back to its checkpoint. |
| `patroller`, `chaser` | Rival marbles: one on a fixed line, one that hunts inside a leash. |
| `portal_pair` | Two linked rings. Speed passes through; each yaw is the way out. |
| `key`, `gate` | A key is carried; a gate opens for one key. |
| `water` | A box of water: slow sinking, drag, and jump becomes a swim stroke. |
| `tip` | A line of text shown on the HUD when the marble gets close. |

## The ruler

Levels are measured against how the marble moves. With the shipped tuning:

| | |
| --- | --- |
| Marble radius | 0.5 |
| Top rolling speed | about 13 units/s |
| Jump height | about 1.4 — steps up to 1.0 are comfortable |
| Jump length from a standstill at the edge | about 2 |
| Jump length with a short run-up | about 4 |
| Super jump height | about 4.5 — walls up to 3.2 |
| Boost pad at 22 into a `curved_ramp` rising 1.6 | carries about 10 |
| Fan hover height | half the column's height above its base |
| Crumbling tile | falls 0.9 s after first contact |
| Double jump | adds another 1.4 on top of wherever the marble is |
| In water | sinks at a fifth of normal gravity; a stroke lifts about 0.6 |
| Leaving water | by a ramp. A stroke at the surface will not clear a ledge |
| Moon gravity (0.35) | jump about 4 high, in the air for about 2 s |

Change `jump_speed`, gravity or the marble's speed and these all move.

A level can also set `gravity_scale` in `_init`. The moon levels use `0.35`,
which makes a jump about 4 units high and two seconds long.

## Rival marbles

Touching one sends the player back to the checkpoint. Landing on it from
above pops it and bounces the player; so does touching it with a shield up.
A popped marble stays gone for the attempt. The decision is made in
`game.gd`, not by a collision: rivals are areas, not solid bodies.

Put a patroller in water and it swims its line; give it a vertical `travel`
and it bobs up and down. A chaser only moves in the horizontal plane.

## Power-ups

Described in `powerups/power_ups.gd`; what each does is in `game/game.gd`.
A power-up takes effect the moment it is touched and runs for a while.
Different ones run side by side, and another of one already running adds its
time, up to three pickups' worth. There is no button to spend one.

| Power-up | Lasts | Effect |
| --- | --- | --- |
| Super jump | 12 s | Jumps are about three and a half times as high |
| Boost | 10 s | A shove on pickup, then a higher top speed |
| Feather | 10 s | Falls at about a third of the level's gravity |
| Magnet | 15 s | Pulls gems within 7 units |
| Stopwatch | 8 s | The clock stops |
| Shield | 12 s | Rival marbles and hazards cannot hurt |
| Double jump | 18 s | One more jump in mid-air |

`_apply_effects` in `game.gd` sets everything a power-up changes on the marble
from what is running now. It is derived from scratch each time rather than
added and removed, so effects ending in any order cannot leave a value stuck.

To add one: add it to the `Kind` enum and the tables in `PowerUps`, give it a
shape in `PowerUpPickup._build_icon`, apply it in `_apply_effects`, and add it
to `Hud.EFFECT_KINDS` so it gets a bar.

The HUD also shows a level's standing conditions (low gravity, water) under
the level name. Those come from `_environment_tags` in `game.gd`.

## Biomes

A biome is a `Biome` resource in `resources/biomes/`: ground, rock and sky
colours and nothing else. To add one, duplicate an existing `.tres`, change the
colours, and point a level's `biome` at it.
