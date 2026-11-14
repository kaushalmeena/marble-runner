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

   If a level that players may already have a time on is rebuilt so that
   the old time could no longer be set, give it a new `id` (the lengthened
   levels are `updraft_2` and so on). The old record is orphaned, which is
   the point: it would otherwise stand as an unbeatable best.

3. Play it to the end. Set the gold time near a clean run and the silver time
   around one and a half times that.

## Long levels: the trail

A level that turns corners is hard to write as raw coordinates. `Trail`
(`levels/trail.gd`) keeps a cursor, the middle of the path's leading edge
and its heading, and each call builds the next stretch from there:

```gdscript
func build(b: LevelBuilder) -> void:
	var t := Trail.new(b)
	t.start()
	t.run(10, 2)            # 10 of floor with 2 gems
	t.gap(3)                # a jump
	t.run(6)
	t.turn(Trail.LEFT)
	t.step(0.8)             # a ledge
	t.run(6)
	t.checkpoint()
	t.glide(18, 6)          # plane, then a leap 18 across and 6 down
	t.run(10, 1)
	t.finish()
```

| Kind | Calls |
| --- | --- |
| Path | `run`, `beam`, `turn`, `start`, `finish`, `checkpoint`, `tip` |
| Up, down, across | `gap`, `step`, `drop`, `ramp`, `bounce`, `fan`, `glide`, `cannon`, `mover`, `bridge` |
| In the way | `crumbles`, `lasers`, `belt`, `slalom`, `ice`, `mud`, `bumpers`, `arena` |
| On the stretch just laid | `power`, `trap`, `patrol`, `sentry`, `key`, `gate` |

Things to know:

- A jump, ledge, glide or cannon needs floor after it to land on: 3 after a
  `gap` or `step`, 8 after a `glide`, 16 after a `cannon`.
- The trail does not check that the path misses itself. Turn in S-bends, or
  climb at least 4 before crossing over an earlier stretch.
- A trail can start anywhere, so a level can be hand-built first and trailed
  after: `Trail.new(b, Vector3(0, 0, -50), 0)`. The later levels of each
  course do this.
- Each call also appends waypoints to `LevelBuilder.route`. Nothing in the
  game reads them; a test harness can drive the marble along them to prove
  the level can be finished. Rivals, beams and traps are not on that line,
  so they still need playing.

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
| `patroller`, `chaser`, `sentry` | Rival marbles: one on a fixed line, one that hunts inside a leash, one that stays put and fires slow shots. |
| `conveyor` | A belt that carries the marble along its arrows, up to belt speed. |
| `mud` | A patch of tar that drags the marble down to a crawl. |
| `laser` | A beam that is lit, then dark, on a timer. Lit, it is a hazard. |
| `bridge`, `button` | A slab of hard light that is only solid while a floor button wired to it is down. A button with `seconds` springs back up. A button can also put out a laser. |
| `cannon` | Lobs the marble onto a set landing spot, whatever the gravity. |
| `trap` | A pickup that harms: one of `PowerUps.AILMENTS`. |
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
| Glide, from a running jump | about 15 across, plus one and a half for every unit of fall. Without it, about two thirds as far |
| In water | sinks at a fifth of normal gravity; a stroke lifts about 0.6 |
| Leaving water | by a ramp. A stroke at the surface will not clear a ledge |
| Moon gravity (0.35) | jump about 4 high, in the air for about 2 s |
| Heavy gravity (1.4) | jump about 1 high; a 15 bounce pad lifts about 4 |
| Conveyor at speed 5 | carries a resting marble at 5; rolling against it is slow but possible |
| In tar | about a third of normal pace |
| Laser | flickers for 0.5 s before it lights |
| Cannon flight of 2.2 s | lands at about 11 units/s over 25 units: leave 10 of run-out |
| Sentry shot | 7 units/s, aimed where the marble was when it fired |

Change `jump_speed`, gravity or the marble's speed and these all move.

## Level-wide conditions

Set in `_init`, in force for the whole level, and named on the HUD and the
level card (`LevelDef.conditions`):

| Field | Effect |
| --- | --- |
| `gravity_scale` | `0.35` is the moon: a jump about 4 high and two seconds long. `1.4` is heavy: a jump about 1 high, gaps of 1.5, steps of 0.6. |
| `wind` | A steady acceleration on the marble, e.g. `Vector3(3, 0, 0)`. Not felt under water or with grip. On ice the wind wins outright, so give a kerb or the grip power-up. Do not put a cannon in a windy level: its shot is not corrected for wind. |
| `dark` | Night. The sun is all but out and the marble carries a lamp. Glowing things (gems, pads, beams) still show. |

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
| Plane | 10 s | Falls at about a third of the level's gravity. Going up is untouched, so jumps are no higher: it is for leaping off something and gliding |
| Magnet | 15 s | Pulls gems within 7 units |
| Stopwatch | 8 s | The clock stops |
| Shield | 12 s | Rival marbles and hazards cannot hurt |
| Double jump | 18 s | One more jump in mid-air |
| Grip | 14 s | Ice grips, and tar and wind do nothing |
| Flare | 14 s | Lights a night level like day |

Three more kinds are *ailments*, placed with `trap`. They use the same
machinery but work against the player, and a shield turns them away:

| Ailment | Lasts | Effect |
| --- | --- | --- |
| Slowed | 6 s | Under half the usual top speed |
| Dizzy | 6 s | Steering is reversed |
| Heavy | 7 s | Gravity up by half, jumps cut by a third |

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
