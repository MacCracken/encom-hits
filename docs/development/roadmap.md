# ENCOM's Hits — Development Roadmap

> **Status**: v0.5.0 in progress | **Last Updated**: 2026-04-15

---

## v0.1.0 — Engine + Light Cycles

The engine and the simplest game. If Light Cycles works, the engine works.

| # | Item | Status | Notes |
|---|------|--------|-------|
| 1 | types.cyr — colors, constants, shared types | Done | Neon palette, screen dims, game IDs, per-game grid constants |
| 2 | engine.cyr — framebuffer init, clear, present | Done | /dev/fb0 direct write + PPM fallback, clock_gettime timing |
| 3 | draw.cyr — Bresenham line, rect, circle | Done | line, hline, vline, rect, filled_rect, pixel, clear |
| 4 | input.cyr — keyboard state, player input | Done | termios raw mode, non-blocking stdin, escape sequences |
| 5 | lightcycles.cyr — grid, trails, collision, win | Done | 176 lines. 80x60 grid, two players, 180-turn prevention |
| 6 | main.cyr — game loop, frame timing | Done | 60fps target, game dispatch, per-game tick rates |

**Exit criteria**: Two light cycles on screen, leaving trails, dying on collision. **Met.**

## v0.2.0 — Grid Bugs

Grid-based movement + pathfinding.

| # | Item | Status | Notes |
|---|------|--------|-------|
| 1 | grid.cyr — grid data structure, intersections | Done | Iterative backtracker maze gen, shared with tanks |
| 2 | ai.cyr — A* pathfinding on grid | Done | A*, chase direction, Light Cycles lookahead AI |
| 3 | gridbugs.cyr — bugs chase player, clear grid | Done | 256 lines. Simple chase (not A*), level progression |

**Exit criteria**: Player moves on grid lines, bugs pursue, score on clearing. **Met.**

## v0.3.0 — Battle Tanks

Projectile physics + ricochet + maze.

| # | Item | Status | Notes |
|---|------|--------|-------|
| 1 | tanks.cyr — tank movement in maze, turret aim | Done | 274 lines |
| 2 | Projectile with wall ricochet (reflection angle) | Done | Up to 2 bounces |
| 3 | AI tank — pathfind to player, fire periodically | Done | Maze-aware A* via ai_find_direction_maze |
| 4 | Procedural maze generation | Done | Iterative backtracker in grid.cyr |

**Exit criteria**: Player tank vs AI tank in maze, shots ricochet off walls. **Met.**

### Known issues
- Tank shot update logic is duplicated between player and AI (minor — keeps each under budget)

## v0.4.0 — MCP Cone

Timing + rotation + pattern.

| # | Item | Status | Notes |
|---|------|--------|-------|
| 1 | mcpcone.cyr — rotating barriers, gap detection | Done | 236 lines, pre-computed 16-segment trig tables |
| 2 | Player projectile through gaps | Done | |
| 3 | Increasing speed per ring cleared | Done | Rings accelerate +1 per broken ring |
| 4 | Core reached = win | Done | |

**Exit criteria**: Navigate through rotating concentric rings to reach the center. **Met.**

## v0.5.0 — Menu + Polish

The collection.

| # | Item | Status | Notes |
|---|------|--------|-------|
| 1 | Game select menu (in main.cyr) | Done | Arrow/WASD nav + number keys. No separate menu.cyr — inline in main |
| 2 | Bitmap text rendering | Done | 3x5 pixel font, A-Z + digits + punctuation, scalable |
| 3 | glow.cyr — bloom effect on bright lines | Done | Single-pass additive, 4-neighbor, brightness threshold |
| 4 | Game-over screens | Done | Winner text + ESC to return |
| 5 | Title cards per game | Not started | Neon text + preview |
| 6 | High score persistence | Not started | Simple file write |
| 7 | Transitions between games | Not started | Fade or wipe |

## v1.0.0 — Complete Collection

| # | Item | Status | Notes |
|---|------|--------|-------|
| 1 | All 4 games complete and polished | In progress | All playable, AI/difficulty need work |
| 2 | Consistent visual identity (neon palette) | Done | All games use shared color palette |
| 3 | Stable 60fps on all games | Done | Frame timing in engine.cyr, simple games |
| 4 | Security audit (input, save files) | Not started | |

## Future (separate repos, separate scope)

| Phase | What | Requires | Notes |
|-------|------|----------|-------|
| **MCP Voice** | Announcer with digital vocal processing | shravan, naad | Pitch down + vocoder + reverb + ring mod. David Warner-style 80s digitized voice. Needs shravan/naad ported first. |
| **Disc Wars** | Arena combat, disc ricochet, catch-and-return | kiran, impetus | Potential licensing conversation |
| **THE GRID** | Interactive world, AI programs, two visual modes | kiran, joshua, impetus | The big one. 1982 wireframe + modern. |

---

*Last Updated: 2026-04-15*
