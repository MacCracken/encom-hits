# ENCOM's Hits — Development Roadmap

> **Status**: Scaffolded | **Last Updated**: 2026-04-14

---

## v0.1.0 — Engine + Light Cycles

The engine and the simplest game. If Light Cycles works, the engine works.

| # | Item | Status | Notes |
|---|------|--------|-------|
| 1 | types.cyr — colors, constants, shared types | Not started | Neon palette defined |
| 2 | engine.cyr — framebuffer init, clear, present | Not started | Same pattern as cyrius-doom |
| 3 | draw.cyr — Bresenham line, rect, circle | Not started | Core primitive: everything is lines |
| 4 | input.cyr — keyboard state, player input | Not started | Arrow keys + WASD for 2 players |
| 5 | lightcycles.cyr — grid, trails, collision, win | Not started | ~200 lines. Two players on a grid. |
| 6 | main.cyr — game loop, frame timing | Not started | 60fps target |

**Exit criteria**: Two light cycles on screen, leaving trails, dying on collision.

## v0.2.0 — Grid Bugs

Grid-based movement + pathfinding.

| # | Item | Status | Notes |
|---|------|--------|-------|
| 1 | grid.cyr — grid data structure, intersections | Not started | Shared with tanks |
| 2 | ai.cyr — A* pathfinding on grid | Not started | Shared AI module |
| 3 | gridbugs.cyr — bugs chase player, clear grid | Not started | ~300 lines |

**Exit criteria**: Player moves on grid lines, bugs pursue via A*, score on clearing.

## v0.3.0 — Battle Tanks

Projectile physics + ricochet + maze.

| # | Item | Status | Notes |
|---|------|--------|-------|
| 1 | tanks.cyr — tank movement in maze, turret aim | Not started | |
| 2 | Projectile with wall ricochet (reflection angle) | Not started | Up to 2 bounces |
| 3 | AI tank — pathfind to player, predict shot angle | Not started | Uses ai.cyr |
| 4 | Procedural maze generation | Not started | Simple recursive backtracker |

**Exit criteria**: Player tank vs AI tank in maze, shots ricochet off walls.

## v0.4.0 — MCP Cone

Timing + rotation + pattern.

| # | Item | Status | Notes |
|---|------|--------|-------|
| 1 | mcpcone.cyr — rotating barriers, gap detection | Not started | |
| 2 | Player projectile through gaps | Not started | |
| 3 | Increasing speed per ring cleared | Not started | |
| 4 | Core reached = win | Not started | |

**Exit criteria**: Navigate through rotating concentric rings to reach the center.

## v0.5.0 — Menu + Polish

The collection.

| # | Item | Status | Notes |
|---|------|--------|-------|
| 1 | menu.cyr — game select screen | Not started | 4 games in a grid |
| 2 | Title cards per game | Not started | Neon text + preview |
| 3 | glow.cyr — bloom effect on bright lines | Not started | The aesthetic |
| 4 | High score persistence | Not started | Simple file write |
| 5 | Transitions between games | Not started | Fade or wipe |
| 6 | MCP voice — announcer with digital vocal processing | Not started | shravan/naad DSP: pitch down + vocoder + reverb + ring mod. David Warner-style 80s digitized voice. |

## v1.0.0 — Complete Collection

| # | Item | Status | Notes |
|---|------|--------|-------|
| 1 | All 4 games complete and polished | Not started | |
| 2 | Consistent visual identity (neon palette) | Not started | |
| 3 | Stable 60fps on all games | Not started | Should be trivial — these are simple |
| 4 | Security audit (input, save files) | Not started | |

## Future (separate repos, separate scope)

| Phase | What | Requires | Notes |
|-------|------|----------|-------|
| **Disc Wars** | Arena combat, disc ricochet, catch-and-return | kiran, impetus | Potential licensing conversation |
| **THE GRID** | Interactive world, AI programs, two visual modes | kiran, joshua, impetus | The big one. 1982 wireframe + modern. |

---

*Last Updated: 2026-04-14*
