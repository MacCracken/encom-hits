# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

### Added
- **Engine layer** — framebuffer init with /dev/fb0 direct write and PPM fallback, clock_gettime frame timing at 60fps (src/engine.cyr)
- **Drawing primitives** — Bresenham line, fast hline/vline, rect, filled rect, pixel, clear (src/draw.cyr)
- **Input system** — termios raw mode, non-blocking stdin, escape sequence parsing for arrow keys, WASD + number keys, terminal restore on shutdown (src/input.cyr)
- **Neon glow effect** — single-pass additive bloom on bright pixels, 4-neighbor spread with brightness threshold (src/glow.cyr)
- **Shared types** — neon color palette, screen constants, direction/result enums, per-game grid dimensions (src/types.cyr)
- **Shared AI** — A* pathfinding on grids, greedy chase direction, Light Cycles lookahead AI with jitter suppression (src/ai.cyr)
- **Grid/maze system** — iterative backtracker maze generation with xorshift PRNG, wall query, maze rendering (src/grid.cyr)
- **Light Cycles** — 80x60 grid, two players with trails, instant-death collision, 180-turn prevention, AI opponent via lookahead (src/lightcycles.cyr)
- **Grid Bugs** — 16x12 node grid with connectivity, bug chase AI, I/O Tower goal, level progression (src/gridbugs.cyr)
- **Battle Tanks** — procedural maze, player vs AI tank, projectile ricochet with max 2 bounces, turret direction indicator (src/tanks.cyr)
- **MCP Cone** — 8 concentric rotating rings with gaps, 16-segment pre-computed trig, projectile through gaps to reach core (src/mcpcone.cyr)
- **Menu system** — game select with arrow/WASD navigation and number keys, 3x5 bitmap font with A-Z/digits/punctuation, game-over screens (src/main.cyr)
- **Main loop** — game dispatch, per-game tick rates (LC: 10/sec, GB: 6/sec, TK: 15/sec, MCP: 20/sec), glow pass per frame
- **Title cards** — 1.5-second neon title screen with preview graphic per game, shown on game select before play begins
- **High score persistence** — scores.dat binary file (4 x i64), loaded at startup, saved on new best. Displayed on menu and game-over screens
- **Score system** — LC: 10/tick survival + 1000 win bonus. GB: 500 * level on clear. TK: 1000 on win. MCP: 100/ring + 1000 win
- **Number rendering** — draw_number function for integer display, digits 0-9 in bitmap font
- **Game-over improvements** — score display, "NEW BEST" indicator on high scores

### Changed
- Tank AI now uses maze-aware A* pathfinding instead of greedy chase (no longer walks into walls)
- MCP Cone rings accelerate by +1 speed each time a ring is broken (difficulty ramp)
- draw_clear uses memset instead of byte-by-byte loop
- Include order: grid.cyr and gridbugs.cyr before ai.cyr (dependency fix)
- Menu shows high scores next to each game name
- Game selection routes through title card instead of instant start
