# Marble Runner

A Godot endless runner: roll a marble down a winding five-lane track that gets
faster the longer you survive. Most content here is data and scenes rather than
code — adding an obstacle or a biome involves no scripting at all.

## Done means it runs

There is no lint, type-check or test suite — this is a Godot project with a
single npm script (`npm run deploy`, which publishes `dist/web` to GitHub
Pages). Verify a change by opening the project in Godot and playing it.

## Reading the codebase

| Working on                            | Read                                                |
| ------------------------------------- | --------------------------------------------------- |
| Project shape, who talks to whom      | [architecture.md](docs/architecture.md)             |
| Adding an obstacle or a pickup        | [adding-obstacles.md](docs/adding-obstacles.md)     |
| Adding or changing a biome            | [biomes.md](docs/biomes.md)                         |

## Conventions

**The world moves, the marble does not.** Read the section of that name in
[architecture.md](docs/architecture.md) before touching movement — it is the
assumption everything else is built on.

**Props carry no scripts.** The single exception is `PowerUpPickup`, and it
carries data (which power-up it grants) rather than behaviour.

**Difficulty and balance are data.** Tune the `Track` node's exported properties
in `game/game.tscn`; re-weight obstacles by editing the `.tres` files in
`resources/spawns/`. Do not hard-code balance in a script.

**Styling goes in the theme.** `resources/theme/marble_runner_theme.tres` is
applied project-wide — prefer a theme type variation over a per-node font or
colour override.

**Jumpability is geometry.** No obstacle carries a "can be jumped" flag; it
follows from collision height versus the jump apex.

**A biome is a palette, not a place.** Nothing about geometry, spawning or
difficulty changes with it, which is why adding one is a single resource file.

## Engine gotchas

Two Godot behaviours cost real debugging time here, both silent failures:

- `FontVariation.variation_opentype` ignores string axis keys. `{"wght": 700}`
  parses without error and does nothing, leaving text at the default weight. It
  needs the integer OpenType tag, so the theme uses `2003265652`.
- An exported node reference (`@export var sun: DirectionalLight3D`) did not
  survive the round trip through the scene file and arrived null. `BiomeDirector`
  takes a `NodePath` and resolves it instead.
