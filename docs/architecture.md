# Architecture

The shape of the project, and the few rules worth knowing before you change
anything.

## Layout

```
autoload/      GameState (score, streak, save file) and SceneManager, Audio
game/          Gameplay root, Track, PowerUpManager, GameCamera, SpawnEntry
player/        The marble
obstacles/     Tree, bush, rock, log and crystal props
collectibles/  Fruit
powerups/      Shield, magnet and slow-mo pickups
effects/       Particle burst emitter
input/         Gesture detection
world/         Ground, lane markers, biome definitions and the biome director
ui/            HUD, main menu, pause menu, death menu
resources/     Shared materials, spawn entries, biomes, environment, UI theme
assets/        Raw imported font and generated audio
```

## The world moves, the marble does not

The marble sits at a fixed `z` and only ever slides between lanes. Everything
else is pulled toward it by `Track`, which owns three things:

- **Movement.** One loop advances every active prop each physics frame. The
  props have no scripts, so there is no per-prop `_physics_process` and no
  `move_and_slide` per obstacle.
- **Lifetime.** Props past the camera are hidden, taken out of collision with
  `monitorable = false`, parked below the world and pushed back into a pool
  keyed by scene path. A long run does not allocate.
- **Spawning.** Distance-driven rather than timed, so obstacle spacing stays
  constant while the speed climbs.

Speed is `base_speed + distance * speed_ramp`, clamped to `max_speed`. The cap
is not cosmetic: without one, props eventually travel further than their own
depth in a single frame and pass straight through the player.

## Who talks to whom

Dependencies run one way, and `game.gd` is the only place that knows the whole
picture:

- `Track` knows nothing about the player or the score.
- `Marble` reports what it touched and nothing more. It is handed its lane
  layout by `game.gd`, rather than looking up the game scene by path.
- `PowerUpManager` owns only countdowns. What a power-up *does* is wired in
  `game.gd`, next to the objects it affects.
- `GameState` owns scoring and persistence. The HUD subscribes to its signals
  and never writes to it.

## Conventions

- **Props carry no scripts.** The one exception is `PowerUpPickup`, which
  carries data (which power-up it grants) rather than behaviour.
- **Difficulty and balance are data.** Tune the `Track` node's exported
  properties in `game/game.tscn`; re-weight obstacles by editing the `.tres`
  files in `resources/spawns/`.
- **Styling goes in the theme.** `resources/theme/marble_runner_theme.tres` is
  applied project-wide, so prefer a theme type variation over a per-node font
  or colour override.
- **Jumpability is geometry.** No obstacle carries a "can be jumped" flag; it
  follows from the collision height versus the jump apex. See
  [Adding an Obstacle](./adding-obstacles.md).

## Engine gotchas

Two Godot behaviours cost real debugging time here, both silent failures:

- `FontVariation.variation_opentype` ignores string axis keys. `{"wght": 700}`
  parses without error and does nothing, leaving text at the font's default
  weight. It needs the integer OpenType tag, so the theme uses `2003265652`.
- An exported node reference (`@export var sun: DirectionalLight3D`) did not
  survive the round trip through the scene file and arrived null.
  `BiomeDirector` takes a `NodePath` and resolves it instead.
