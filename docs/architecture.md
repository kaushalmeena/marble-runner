# Architecture

The shape of the project, and the few rules worth knowing before you change
anything.

## Layout

```
autoload/      GameState (progress, gems, secret diamonds, skins), SceneManager, Audio, Controls
game/          Gameplay root, the orbit camera and the cheat codes
player/        The marble
levels/        LevelDef, LevelBuilder, Trail, LevelCatalog, and one script per level
gimmicks/      Gems, the secret diamond, finish, checkpoints, pickups, pads,
               bumpers, movers, fans, belts, tar, beams, button bridges,
               cannons, rival marbles, portals, keys and gates, water
powerups/      The table describing each power-up
effects/       Particle burst emitter
world/         The tile shader, shared material helpers, biome palettes
skins/         Marble skins and their catalogue
ui/            Ui helpers, drawn icons, HUD, results card, level select, menus, shop
resources/     Biomes, the sky, skins, the UI theme
assets/        Raw imported font and generated audio
```

## The marble is rolled, not steered

The marble is a `RigidBody3D`. Input never sets its velocity: it applies a
torque about the axis at right angles to the held direction, the marble spins,
and friction with the floor turns that spin into travel. A small direct push is
added on top so it responds at once, and is all the control there is in the air.

On level, grippy ground there is one assist: motion the player is not asking
for is bled off. With nothing held the marble slows to a stop; with a
direction held, its sideways drift goes; and steering against its travel
pushes harder. Friction alone would let it coast for ever and swing wide on
every turn. Ice, slopes, water, moving platforms and a marble flung faster
than its top speed are all left alone (`Marble._steady`).

Everything interesting falls out of that one decision:

- **Ice** is just low friction: the spin has nothing to bite on, so the marble
  keeps the speed it arrived with.
- **Ramps** launch, because the marble has real momentum.
- **Bumpers, pads and fans** only add velocity or force. They do not need to
  know anything about how the marble moves.

All of it happens in `Marble._integrate_forces`, the one place a rigid body can
be read and changed without fighting the solver. Ground is detected from that
step's contact normals, which is also where coyote time, the jump buffer and
landing detection live.

"Forward" belongs to the camera. `GameCamera` owns the heading, hands it to the
marble every frame, and drifts round behind the direction of travel when left
alone, so the movement keys alone are enough to play.

## Levels are built, not authored

A level is a `LevelDef` subclass. Its `build(b)` calls `LevelBuilder`:
`b.floor(...)`, `b.gem(...)`, `b.mover(...)`. The builder owns every mesh,
collision shape and material, and returns lists of the things the game needs to
listen to. See [Levels](./levels.md).

Long levels are laid out with `Trail`, a helper over the builder that keeps a
cursor and builds one stretch at a time: run, turn, gap, climb, glide. The
later levels of each course are hand-built for their first half and trailed
for their second.

`LevelCatalog` holds the scripts in unlock order. The menus build a real level
behind themselves through the same builder, so there is no separate "menu art".

## Who talks to whom

Dependencies run one way, and `game.gd` is the only place that knows the whole
picture:

- `Marble` knows nothing about levels, gems or the clock. Anything it bumps
  into that has an `on_marble_hit` method gets told; that is the whole contract.
- Gimmicks act on the marble directly. A `BoostPad` calls `marble.boost()`.
- Gems, the secret diamond, pickups, checkpoints, hazards, rival marbles,
  cannons, keys, gates and the finish emit a signal and do nothing else. `game.gd` connects them and
  decides what they mean.
- `Cheats` recognises typed words and nothing more. What a code does is in
  `game.gd`. A run that used one is finished but not recorded.
- `PowerUps` describes each power-up. What one *does* is wired in `game.gd`,
  next to the objects it affects.
- `GameState` owns progress and persistence. The game reports a finished level
  through `complete_level()`; the UI only reads.
- `Hud` is told what to show and never reaches into the game.

## Progress

A level is finished by touching the finish with every gem collected. The save
file keeps the best time per level id; stars are derived from that time against
the level's gold and silver targets, never stored. A level unlocks when the one
before it has been finished. Gems are the currency: every gem collected is banked
on every finish, with a bonus per star and per secret diamond the first time
each is earned, and they are spent on skins. The save also lists the levels
whose secret diamond has been carried to the finish.

Falling off, or touching a hazard, returns the marble to the last checkpoint.
The clock keeps running: a fall costs time, not the attempt.

## Conventions

- **Never set the marble's velocity from input.** Add torque or force.
- **Levels never touch meshes or materials.** If a level needs something the
  builder cannot do, add it to the builder.
- **Styling goes in the theme.** `resources/theme/marble_runner_theme.tres` is
  applied project-wide, so prefer a theme type variation over a per-node font
  or colour override.
- **Input bindings live in `autoload/controls.gd`**, as a table, not in
  `project.godot`.

## Engine gotchas

See [AGENTS.md](../AGENTS.md#engine-gotchas). They are kept in one place.
