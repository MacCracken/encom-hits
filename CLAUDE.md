# ENCOM's Hits — Claude Code Instructions

## Project Identity

**ENCOM's Hits** — Retro arcade game collection in Cyrius. Six games sharing a common engine, rendered in neon-on-black wireframe aesthetic.

- **Type**: Standalone game binary (Cyrius-native)
- **License**: GPL-3.0-only
- **Version**: SemVer, currently 1.0.0
- **Version file**: `VERSION` at repo root
- **Genesis repo**: [agnosticos](https://github.com/MacCracken/agnosticos)
- **Sister projects**: [cyrius-doom](https://github.com/MacCracken/cyrius-doom) (3D BSP), [cyrius-nba-jam](https://github.com/MacCracken/cyrius-nba-jam) (2D sprites)

## What This Is

A collection of six arcade games inspired by the 1982 TRON cabinet and Discs of TRON (1983), sharing a common engine. Pure software rendering — neon wireframe lines on black, no textures, no sprites, no assets. The art is math.

### The Games

**Light Cycles** — Two players leave walls behind them on a grid. Last one standing wins. Instant death on any collision (wall, trail, boundary). The most iconic game in the collection.

**Grid Bugs** — Clear bugs from an energy grid. Movement on grid lines, bugs pursue via pathfinding. Reach the I/O Tower to advance. Pac-Man reimagined on a circuit board.

**Battle Tanks** — Top-down tank combat in a procedural maze. Projectile physics with wall ricochet. AI opponent with maze-aware A* pathfinding.

**MCP Cone** — Navigate through rotating concentric barriers to reach the core. Timing-based, pattern recognition, increasing speed per ring cleared.

**Interceptors** — Vertical shooter. Defend the grid from waves of descending interceptor programs. Shoot to survive, dodge enemy fire.

**Disc Arena** — 1v1 disc combat inspired by Discs of TRON. Throw your disc, ricochet off walls, hit the opponent. First to 5 wins.

## Why This Project Exists

1. **Proves shared game infrastructure.** Six games on one engine — the kiran pattern before kiran exists. Shared renderer, input, game loop, menu system.

2. **Zero-asset rendering.** Every visual is a line, arc, or filled polygon computed at runtime. No sprite loading, no texture management, no asset pipeline. Pure math. This validates framebuffer rendering primitives that every game engine needs.

3. **The t-ron connection.** The AGNOS security monitor is named t-ron — the security program from TRON that fights the MCP. ENCOM is the fictional company from the same universe. This collection ships games from the company whose security program already runs in the OS.

4. **Small scope, high polish.** Each game is 200-300 lines. The whole collection is ~3.9K lines. Small enough to finish, polished enough to showcase.

## Architecture

```
src/
  main.cyr          — Entry, menu, bitmap text, splash, scoring, --ppm mode
  engine.cyr        — Framebuffer, /dev/fb0 + PPM output, frame timing
  draw.cyr          — Bresenham line, hline/vline, rect, filled rect, pixel
  input.cyr         — Terminal raw mode, keyboard state, escape sequences
  glow.cyr          — Additive neon bloom effect
  ai.cyr            — A* (open grid + maze-aware), chase, LC lookahead
  grid.cyr          — Maze generation (iterative backtracker), wall query
  types.cyr         — Colors, constants, game IDs, per-game grid dimensions
  lightcycles.cyr   — Light Cycles game
  gridbugs.cyr      — Grid Bugs game
  tanks.cyr         — Battle Tanks game
  mcpcone.cyr       — MCP Cone game
  interceptors.cyr  — Interceptors game
  discs.cyr         — Disc Arena game
```

### Rendering

**Framebuffer-based, neon wireframe:**
- 320x240 or 640x480 framebuffer
- Background: pure black (0x000000)
- Lines: bright neon colors (cyan, orange, red, green, white)
- Glow: 1-2 pixel bloom around bright lines (additive blend on adjacent pixels)
- No textures. No sprites. No asset files. Every pixel is computed.

**The 1982 aesthetic is the design constraint.** The original TRON cabinet rendered vector graphics on a standard raster display. Colored lines on black. That's the look — it's also zero-asset, which means the entire game is code. No art pipeline, no asset loading, no format parsing.

### Line Drawing

The core rendering primitive is `draw_line(x0, y0, x1, y1, color)` — Bresenham's algorithm. Everything builds from this:
- Light cycle trails: sequences of horizontal/vertical lines
- MCP cone barriers: concentric circles drawn as polygon approximations
- Tank maze: grid of line segments
- Grid bugs: grid intersections connected by lines
- Interceptor enemies: rectangles with legs (recognizer shapes)
- Disc Arena: diamond-shaped discs, paddle bars
- Text: 3x5 bitmap font, A-Z + 0-9 + punctuation, scalable
- Splash: large vector ENCOM lettering + perspective grid

### Shared AI

`ai.cyr` provides pathfinding (A* on a grid) used by:
- Battle Tanks: AI tank navigates maze to find player, predicts shot angles
- Grid Bugs: bugs chase player via shortest path on grid
- Light Cycles (AI opponent): avoid walls, maximize opponent's constraint

## Development Process

### Work Loop (continuous)

1. Work phase — implement game, add to menu
2. Build: `cyrius build src/main.cyr build/encom-hits`
3. Play test — feel, timing, difficulty curve
4. Benchmark: frame time (target: <4ms for 240fps — these are simple games)
5. Documentation — CHANGELOG
6. Return to step 1

### Build Order (completed)

1. Engine (framebuffer, line drawing, input, glow)
2. Light Cycles (simplest game, proves the engine)
3. Grid Bugs (proves grid + pathfinding)
4. Battle Tanks (proves projectiles + ricochet + maze A*)
5. MCP Cone (proves rotation + timing + pattern)
6. Interceptors (proves wave spawning + multi-entity collision)
7. Disc Arena (proves ricochet physics + AI prediction)
8. Menu system, title cards, splash screen
9. Scoring, high score persistence, screenshot mode
10. Security audit + pre-release review

## DO NOT

- **Do not commit or push** — the user handles all git operations
- **NEVER use `gh` CLI** — use `curl` to GitHub API only
- Do not add unnecessary dependencies
- Do not use sprites or textures — every visual is a computed line/shape
- Do not include any trademarked names or Disney/TRON IP in the shipped binary — the games are original implementations inspired by 1982 arcade mechanics
- **Keep it simple.** Each game should be 200-500 lines. If a game exceeds 800 lines, it's overscoped.

## Visual Identity

The neon-on-black aesthetic is the brand:

| Element | Color | Hex |
|---------|-------|-----|
| Player 1 / Cycle 1 | Cyan | `0x00FFFF` |
| Player 2 / Cycle 2 | Orange | `0xFF8800` |
| Walls / Barriers | Blue | `0x0044FF` |
| Projectiles / Energy | White | `0xFFFFFF` |
| Enemies / Bugs | Red | `0xFF0000` |
| Power-ups / Goals | Green | `0x00FF00` |
| Grid lines | Dim blue | `0x001133` |
| Background | Black | `0x000000` |
| Glow | Additive blend, 50% brightness on adjacent pixels |

## Future Phases (not in this repo)

**MCP Voice** — Announcer with digital vocal processing. Requires shravan/naad porting. Pitch down + vocoder + reverb + ring mod. David Warner-style 80s digitized voice.

**THE GRID** — Fully interactive world. 1982 wireframe mode AND modern mode. joshua provides AI programs as NPCs. This is a world, not a mini-game. Separate repo, separate scope, separate conversation with Disney.

## Documentation Structure

```
Root files (required):
  README.md, CHANGELOG.md, CLAUDE.md, CONTRIBUTING.md, SECURITY.md, CODE_OF_CONDUCT.md, LICENSE

docs/ (required):
  development/roadmap.md — phased milestones
  sources/tron-arcade.md — original 1982 cabinet mechanics reference
```

## CHANGELOG Format

Follow [Keep a Changelog](https://keepachangelog.com/). Frame time benchmarks for each game.
