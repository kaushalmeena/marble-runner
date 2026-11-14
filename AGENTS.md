# Marble Runner

A Godot marble platformer: roll, jump, swim and glide a physics marble through
sixty floating levels, collect every gem, reach the finish, beat the clock,
and find the secret diamond hidden in each. Levels are short scripts, not
scenes — adding one involves no editor work at all.

## Done means it runs

There is no lint, type-check or test suite — this is a Godot project with a
single npm script (`npm run deploy`, which publishes `dist/web` to GitHub
Pages). Verify a change by running it:

```bash
godot --headless --import            # surfaces script errors
godot                                # play it
```

A level is only done when it has been finished by hand, start to finish, and
its secret diamond found by hand too.

## Reading the codebase

| Working on                            | Read                                        |
| ------------------------------------- | ------------------------------------------- |
| Project shape, who talks to whom      | [architecture.md](docs/architecture.md)     |
| Adding a level, a gimmick or a biome  | [levels.md](docs/levels.md)                 |

## Conventions

**The marble is rolled, not steered.** Input applies torque; friction turns spin
into travel. Never set the marble's velocity from input. Read the section of
that name in [architecture.md](docs/architecture.md) before touching movement.

**Levels are scripts.** A level is a `LevelDef` subclass in `levels/defs/` that
calls `LevelBuilder`. It never creates a mesh, a shape or a material itself.
Long levels are laid out with `Trail`, which builds one stretch at a time
from a moving cursor and records the route a test bot follows.

**Gimmicks act on the marble by themselves.** A bumper bumps, a fan lifts.
`game.gd` only hears about what changes the state of the run: gems, pickups,
checkpoints, hazards, the finish.

**Jump numbers are the level designer's ruler.** A jump clears about 1.4 units
up, and about 4 units across from a short run-up. Change `jump_speed` or gravity
and every level needs replaying.

**Menus are built in code.** Every screen is assembled in its script through
`Ui`, with drawn `Icon`s instead of font glyphs. Scene changes go through
`SceneManager`, which fades between them.

**Styling goes in the theme.** `resources/theme/marble_runner_theme.tres` is
applied project-wide — prefer a theme type variation over a per-node font or
colour override. Interface built in code goes through `Ui`.

**Nothing on the HUD moves anything else.** Readouts have fixed footprints, and
the clock is laid out per character so it does not twitch as digits change.

**A biome is a palette, not a place.** Nothing about geometry or difficulty
changes with it, which is why adding one is a single resource file.

## Engine gotchas

Silent failures that cost real debugging time here:

- `FontVariation.variation_opentype` ignores string axis keys. `{"wght": 700}`
  parses without error and does nothing, leaving text at the font's hairline
  default weight. It needs the integer OpenType tag, `2003265652`.
- Two touching boxes on *separate* bodies leave a seam the marble catches at
  speed and is kicked into the air by. Every fixed box in a level is a shape on
  one `StaticBody3D`, and the Jolt contact slop in `project.godot` is tightened.
  Merging alone did not stop the kick; the tighter slop did. Movers and
  crumbling tiles are still separate bodies, so keep them level with the floor.
- A physics material belongs to a body, not a shape, so ice cannot be a
  low-friction floor. Ice shapes carry a metadata flag and the *marble* lowers
  its own friction while standing on one.
- An `AnimatableBody3D` synced to physics does not report its new position until
  later. `Mover` derives its velocity from its motion curve instead.
- `Engine.time_scale` stretches each physics step rather than running more of
  them. A harness that speeds the game up five times is simulating at 12 Hz,
  and reports failures that do not exist. Raise
  `Engine.physics_ticks_per_second` by the same factor.
- Two transparent faces in the same plane as an opaque one flicker. Water is a
  single sheet just below the rim, never a box filling the pool.
- `Key` is a global enum (keycodes). A class named `Key` fails to parse with a
  baffling "cannot assign Key to Key". The pickup is `GateKey`.
- A container owns its children's position and scale and takes them back
  whenever it re-sorts. Menu animations tween only opacity on anything a
  container lays out; things that slide sit in a plain `Control` first.
- The marble has air damping. Anything that throws it a set distance (the
  cannon) has to solve for it, or a two second flight lands a quarter short.
- A light at the centre of the marble lights everything but the marble. The
  night lamp is held above it.
- A cannon's shot is worked out for a plain fall. A plane or a wind
  would carry the marble past the landing: the blast tears the plane away, and
  windy levels have no cannons.
- A ball free to roll receives only 2/7 of a moving platform's acceleration
  through friction. The marble is handed the rest directly, or it is left behind.
