# ENCOM's Hits — Development Roadmap

> **Status**: v0.6.3 (Cyrius 6.5.36 toolchain) — pre-1.0 hardening | **Last Updated**: 2026-08-31

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
| 2 | Bitmap text rendering | Done | 3x5 pixel font, A-Z + 0-9 + punctuation, scalable. draw_number for scores |
| 3 | glow.cyr — bloom effect on bright lines | Done | Single-pass additive, 4-neighbor, brightness threshold |
| 4 | Game-over screens | Done | Winner text, score display, "NEW BEST" indicator, ESC to return |
| 5 | Title cards per game | Done | 1.5s neon title + preview graphic + best score per game |
| 6 | High score persistence | Done | scores.dat binary file (4 x i64), read on startup, write on new best |
| 7 | Transitions | Done | Title card serves as visual break between menu and game |

## v0.6.0 — Cyrius 6.0.x Migration

Onto the modern toolchain + ready for a first tag.

| # | Item | Status | Notes |
|---|------|--------|-------|
| 1 | `cyrius.toml` → `cyrius.cyml` manifest | Done | `[package]`/`[build]`/`[deps]`, pinned `cyrius = "6.0.52"`, `lib/` via `cyrius deps` |
| 2 | 6.x toolchain compatibility | Done | Fixed the `enum*enum*literal` const mis-fold that under-sized the framebuffer (see CHANGELOG) |
| 3 | Test suite on 6.x | Done | `tests/encom-hits.tcyr` — `assert_*` framework, 13 assertions, `cyrius test tests/encom-hits.tcyr` |
| 4 | CI + release workflows | Done | `.github/workflows/{ci,release}.yml` mirroring cyrius-polyomino; bare-SemVer tags |

**Exit criteria**: clean build + green CI on the 6.0.52 toolchain, tag-able. **Met.**

## v0.6.1 — Framebuffer Display Fix

Made the games render correctly on a real Linux console instead of tiling into
the top band of the panel.

| # | Item | Status | Notes |
|---|------|--------|-------|
| 1 | Probe real panel geometry | Done | `FBIOGET_VSCREENINFO` / `FBIOGET_FSCREENINFO` ioctls in `engine_init` |
| 2 | Integer-scale + center the surface | Done | New `engine_blit`; honors the panel's `line_length` pitch and bit depth (32bpp BGRX, 16bpp RGB565) |
| 3 | Graceful degradation | Done | PPM fallback unchanged when `/dev/fb0` is unavailable |

**Exit criteria**: correct full-screen render on real hardware. **Met.**

## v0.6.2 — Cyrius 6.5.36 Toolchain

Toolchain + dependency refresh. No game-logic changes.

| # | Item | Status | Notes |
|---|------|--------|-------|
| 1 | Toolchain pin 6.0.52 → 6.5.36 | Done | `cyrius.cyml` `[package].cyrius`; clears the `cycc`/manifest drift warning |
| 2 | Vendored stdlib refreshed | Done | `cyrius deps` closure grew 9 → 17 files (`assert` now includes `syscalls`, `alloc` includes `atomic`) |
| 3 | Dormant `[deps.vani]` pin refreshed | Done | 0.9.4 → 1.2.2, and the false "cyrius-doom pins 0.9.4" note corrected |
| 4 | Doc/version sweep | Done | README toolchain floor + line counts, CLAUDE.md version, this roadmap, CHANGELOG |

**Exit criteria**: clean build + 13/13 tests + all 14 `--ppm` frames on 6.5.36. **Met.**

## v0.6.3 — P-1 Audit & Hardening (current)

Six-lens audit of `src/` (memory safety, security, correctness, performance,
structure, robustness), every acted-on finding independently verified. Two games
were broken as designed; the display path could not hold 60fps on a normal monitor.

| # | Item | Status | Notes |
|---|------|--------|-------|
| 1 | Function-local array sizing | Done | Five sites to file-scope `.bss`; see item 2a under hardening below |
| 2 | MCP Cone render/hit desync | Done | Renderer ignored rotation entirely — no ring ever appeared to turn; both paths now share `_mcp_seg_at` |
| 3 | Disc Arena AI dodge direction | Done | "Dodge" was a verbatim copy of "catch" — the AI stepped into every throw |
| 4 | "NEW BEST" unreachable | Done | Compared against an already-updated high score; now a flag set where the comparison happens |
| 5 | `engine_blit` out-of-bounds write | Done | A panel smaller than the 320x240 surface overran `_fb_blit`; extent now clamped |
| 6 | Framebuffer probe hardening | Done | ioctl returns checked, bpp whitelisted to 16/32, geometry bounded, `alloc` guarded |
| 7 | Per-frame cost | Done | `draw_clear` 443 → 49 us; `engine_blit` off the 15.1 ms byte-wise `memcpy`; glow black fast-reject; PPM fallback throttled from 60/s to ~1/s |
| 8 | `O_NOFOLLOW` + mode 0600 on created files | Done | The 14 `/tmp` PPMs and the relative-path `scores.dat` |
| 9 | Regression cover for paths CI cannot reach | Done | `tests/engine-blit.tcyr` (5), `tests/mcpcone-rotation.tcyr` (9), both mutation-checked; CI moved to `cyrius tests` |

**Exit criteria**: clean build + 27 assertions across 3 suites + all 14 `--ppm` frames, renders pixel-neutral except the MCP Cone fix. **Met.**

## v0.7.0 → v0.9.0 — Pre-1.0 Hardening

The room before 1.0.0. No new games — confidence work.

| # | Item | Status | Notes |
|---|------|--------|-------|
| 1 | Full hands-on play-test pass (all 6 games, real `/dev/fb0`) | Pending | Live input/feel/difficulty/frame-pacing — the one thing headless `--ppm` can't cover |
| 2 | Bug audit + fixes | Pending | Triage anything play-testing surfaces |
| 2a | Function-local array sizing | Done | A function-local `var X[N]` reserves ONE 8-byte slot, not `N`. All five sites that indexed past it via `store64(&X + i*8, …)` are now file-scope `.bss` like `_ai_*`: `_draw_digits[8]` (`main.cyr`), `_maze_cand_dir[4]` (`grid.cyr`), `_engine_ts[2]` / `_engine_now_ts[2]` / `_engine_sleep_ts[2]` (`engine.cyr`). The `draw_number` site was **not** benign as previously recorded — it corrupted the menu and title cards whenever `scores.dat` held a non-zero score; the committed screenshots hid it by being captured with no `scores.dat`, so every call took the `num == 0` early return. `input.cyr` `buf[4]` stays a local (1-byte reads at offset 0 only). +144 bytes static; renders byte-identical where it was already correct, and maze output identical across 200 seeds |
| 2b | Game-feel defects found in the 0.6.3 audit | Pending | Tanks player movement is not tick-gated (holding a direction outruns the AI *and* the player's own projectiles); Tanks AI paths onto the player's own cell and stops, hiding the player; Interceptors freezes every bullet in flight for ~1.5 s between waves; Light Cycles decides head-on collisions by update order, always killing P2; MCP Cone has no lose condition; `gb_score` is a dead second scoring path. Deliberately deferred — each wants play-testing alongside the fix |
| 2c | Disc Arena difficulty re-balance | Pending | 0.6.3 made the AI actually dodge instead of walking into throws; the right dodge speed is a feel question the headless suite cannot answer |
| 3 | Deep security audit | Pending | Input parsing, save-file I/O, bounds. 0.6.3 covered the framebuffer probe/blit, `O_NOFOLLOW` on created files, and the `scores.dat` read path; the escape-sequence parser in `input.cyr` is the main remaining surface |
| 4 | Cross-target build check | Pending | `--aarch64` / other targets if in scope |

## v1.0.0 — Release (target, after hardening)

First public tag — ships once the 0.7→0.9 hardening clears.

| # | Item | Status | Notes |
|---|------|--------|-------|
| 1 | All 6 games complete and polished | Done | LC, GB, TK, MCP, INT, DISC — all playable with AI, scoring, high scores |
| 2 | Consistent visual identity (neon palette) | Done | All games use shared color palette |
| 3 | Stable 60fps on all games | Done | Frame timing in engine.cyr, simple games |
| 4 | Initial security pass (input, save files) | Done | See CHANGELOG — 7 fixes across input, memory, file I/O |
| 5 | Play-test + bug + security audit cleared | Pending | Gated on v0.7→v0.9 above |

## Future (separate repos, separate scope)

| Phase | What | Requires | Notes |
|-------|------|----------|-------|
| **MCP Voice** | Announcer with digital vocal processing | shravan, naad | Pitch down + vocoder + reverb + ring mod. David Warner-style 80s digitized voice. Needs shravan/naad ported first. |
| **Disc Wars** | Full 3D arena disc combat | kiran, impetus | Disc Arena (2D) ships in v1.0; 3D version is a separate effort |
| **THE GRID** | Interactive world, AI programs, two visual modes | kiran, joshua, impetus | The big one. 1982 wireframe + modern. |

---

*Last Updated: 2026-08-31*
