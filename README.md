# MarbleRunner

A godot game about endless runner with dynamic obstacle generation.

Live version is deployed at [https://kaushalmeena.github.io/marble-runner/](https://kaushalmeena.github.io/marble-runner/)

## Gameplay

Roll down a five-lane track that scrolls at you faster the longer you survive.
Dodge trees and bushes, collect fruit to score, and try to beat your personal
best. The obstacles ahead are picked from a weighted table, so no two runs lay
out the same way.

| Action       | Keys                     |
| ------------ | ------------------------ |
| Switch lanes | `←` `→` or `A` `D`       |
| Pause        | `Esc` or `P`             |
| Menus        | Arrow keys, `Enter`      |

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development purposes.

### Requirements

To install and run this project you need:

- [Godot 4.7](https://godotengine.org/download/ "Godot 4.7") (uses the Compatibility renderer)
- [NodeJS](https://nodejs.org/ "NodeJS")
- [git](https://git-scm.com/downloads "git") (only to clone this repository)

### Installation

To set up everything in your local machine, you need to follow these steps:

1. Clone this repo onto your computer:

```bash
git clone https://github.com/kaushalmeena/marble-runner.git
```

2. Open Godot and click on Import->Browse

3. Navigate to `marble-runner` folder and click Open

## Project Structure

```
autoload/      GameState (score + save file) and SceneManager (transitions)
game/          Gameplay root, the Track that scrolls the world, spawn table type
player/        The marble
obstacles/     Tree and bush props (plain Area3D scenes, no scripts)
collectibles/  Fruit
world/         The ground and its lane markers
ui/            HUD, main menu, pause menu, death menu
resources/     Shared materials, spawn table entries, environment, UI theme
assets/        Raw imported assets
```

A few conventions worth knowing before editing:

- **Props carry no scripts.** `Track` owns the movement, recycling and lifetime
  of everything that scrolls past. Adding an obstacle means adding a scene with
  an `Area3D` root in the `obstacle` group, plus a `SpawnEntry` resource.
- **Difficulty and spawn balance are data, not code.** Tune the `Track` node's
  exported properties in `game/game.tscn`, and re-weight obstacles by editing
  the `.tres` files in `resources/spawns/`.
- **The UI never owns game state.** Score lives in `GameState`; the HUD only
  subscribes to its signals.
- **Styling goes in the theme.** `resources/theme/marble_runner_theme.tres` is
  applied project-wide, so prefer a theme type variation over a per-node font
  or colour override.

## Contributing

Contributions are welcome! If you find a bug or have a feature request, please
[open an issue](https://github.com/kaushalmeena/marble-runner/issues/new/choose)
first to discuss it. For code changes, fork the repository, create a branch,
and open a pull request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
