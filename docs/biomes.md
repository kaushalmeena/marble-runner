# Biomes

A biome is a palette, not a place. Nothing about geometry, spawning or
difficulty changes with it, which is why adding one is a single resource file
and no code.

## How the blend works

`BiomeDirector` reads the track's distance and cross-fades between consecutive
biomes. The list wraps, so a long enough run loops back to the first.

- `distance_per_biome` (default 900) is how far each biome holds.
- `blend_fraction` (default 0.35) is how much of that is spent fading into the
  next one. The first 65% of a biome is its own colour; the last 35% is a
  smoothstep into the next.

Rather than swapping anything, the director writes colours onto the **shared**
material and environment resources. Every prop on the track uses those same
resources, so one write re-skins the whole world. Nothing is saved to disk;
these are the runtime copies.

## Adding one

Create `resources/biomes/<name>.tres` with `script_class="Biome"` and fill in
the colours:

| Property                              | Tints                                  |
| ------------------------------------- | -------------------------------------- |
| `ground_color`, `stripe_color`        | The track surface and its lane markers |
| `foliage_color`, `bark_color`, `rock_color` | Props                            |
| `fog_color`                           | Distance haze, and the sky's ground half |
| `sky_top_color`, `sky_horizon_color`  | The sky gradient                       |
| `sky_ground_color`                    | Below the horizon                      |
| `sun_color`                           | The directional light                  |

Then add it to the `biomes` array on the **BiomeDirector** node in
`game/game.tscn`. Order in that array is the order they appear in.

## Keeping the horizon clean

Props spawn at `z = -95`, past the environment's `fog_depth_end` of 108, so they
fade in out of the haze instead of popping into existence.

That only works while the fog matches what is behind it. The director pins the
sky's `ground_horizon_color` to the biome's `fog_color` for exactly this reason,
so the far end of the track melts into the horizon with no visible seam. If you
add a biome whose fog and sky disagree, that seam comes back.
