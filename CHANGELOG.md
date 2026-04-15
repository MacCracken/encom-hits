# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [1.0.0] — 2026-04-15

Six-game arcade collection. Shared engine, neon wireframe rendering, zero assets. 3,872 lines across 14 source files.

### Added
- **Engine layer** — framebuffer init with /dev/fb0 direct write and PPM fallback, clock_gettime frame timing at 60fps, parameterized PPM writer (src/engine.cyr)
- **Drawing primitives** — Bresenham line, fast hline/vline, rect, filled rect, pixel, memset clear (src/draw.cyr)
- **Input system** — termios raw mode, non-blocking stdin, escape sequence parsing for arrow keys, WASD + number keys 1-6, Ctrl+C graceful quit, terminal restore on shutdown (src/input.cyr)
- **Neon glow effect** — single-pass additive bloom on bright pixels, 4-neighbor spread with brightness threshold (src/glow.cyr)
- **Shared types** — neon color palette, screen constants, direction/result enums, per-game grid dimensions (src/types.cyr)
- **Shared AI** — A* pathfinding on open grids, maze-aware A* with wall checking, greedy chase direction, Light Cycles lookahead AI with jitter suppression (src/ai.cyr)
- **Grid/maze system** — iterative backtracker maze generation with xorshift PRNG, wall query, maze rendering (src/grid.cyr)
- **Light Cycles** — 80x60 grid, two players with trails, instant-death collision, 180-turn prevention, head-on collision detection, AI opponent via lookahead (src/lightcycles.cyr)
- **Grid Bugs** — 16x12 node grid with connectivity, bug chase AI with clamped spawn coordinates, I/O Tower goal, level progression with death-guard (src/gridbugs.cyr)
- **Battle Tanks** — procedural maze, player vs AI tank with maze-aware A* pathfinding, projectile ricochet with max 2 bounces, turret direction indicator (src/tanks.cyr)
- **MCP Cone** — 8 concentric rotating rings with gaps, 16-segment pre-computed trig, projectile through gaps to reach core, speed ramp on ring destruction (src/mcpcone.cyr)
- **Interceptors** — vertical shooter with wave spawning, recognizer-shaped enemies with horizontal drift, player/enemy bullet systems, wave-clear progression (src/interceptors.cyr)
- **Disc Arena** — 1v1 disc combat, throw/ricochet/catch mechanics, top/bottom wall bounces, AI opponent with dodge/aim/throw behaviors, first-to-5 scoring (src/discs.cyr)
- **Splash screen** — large vector "ENCOM" lettering, "TOP HITS" in red, perspective grid floor with vanishing point, 4-second display with any-key skip
- **Menu system** — 6-game select with arrow/WASD navigation and number keys, corner bracket title framing, end-capped dividers, high score display per game
- **Bitmap text** — 3x5 pixel font with A-Z, 0-9, punctuation, scalable rendering. draw_number for integer display with 8-digit overflow guard
- **Title cards** — 1.5-second neon title screen with preview graphic per game, best score display, shown before game start
- **High score persistence** — scores.dat binary file (6 x i64), loaded at startup with validation/clamping, saved on new best with 0644 permissions
- **Score system** — LC: 10/tick + 1000 win. GB: 500 * level. TK: 1000 win. MCP: 100/ring + 1000 win. INT: 100/kill. DISC: 200/point
- **Screenshot mode** — `--ppm` CLI flag renders splash, menu, 6 title cards, 6 gameplay screens to /tmp/ as PPM files and exits
- **Game-over screens** — score display, "NEW BEST" indicator (strict >), ESC to return

### Security
- Score file validation clamps values to [0, 99999999] on load
- draw_number overflow guard (8-digit cap)
- PPM buffer pre-allocated once (no per-frame leak)
- Ctrl+C maps to graceful quit (ETX byte 3 → KEY_Q)
- File permissions 0644 on scores.dat and PPM output
- Xorshift PRNG zero-trap guard
- Bug spawn coordinates clamped to valid grid bounds
