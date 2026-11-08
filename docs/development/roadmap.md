# ENCOM's Hits — Development Roadmap

> **Status**: v0.8.2 (Cyrius 6.7.18 toolchain) — pre-1.0 hardening | **Last Updated**: 2026-11-07

This file tracks only what is left. Shipped work, release by release, is recorded in
[CHANGELOG.md](../../CHANGELOG.md).

**Where things stand:** all six games are complete and playable with AI, scoring and
persistent high scores, on one shared engine: framebuffer with `/dev/fb0` blit, Bresenham
drawing, raw-mode input, glow, A*, and maze generation. The road to 1.0.0 is confidence
work, not features. No new games.

| Release | Theme | State |
|---------|-------|-------|
| v0.8.2 | Quick wins: roadmap cleanup, cross-target check, CI gates | **Current** |
| v0.8.3 | P(-1) sweep: audit, refactor, hardening, optimization, repair | Next |
| v0.8.4 | Play-test and difficulty tuning on real hardware | Planned |
| v0.9.0 | Release candidate: `cyrius audit` clean, aarch64 on hardware, docs final | Planned |
| v1.0.0 | Release | Target |

---

## v0.8.2 — Quick Wins (current)

The open items that could be closed without a design decision or a play-test.

| # | Item | Status | Notes |
|---|------|--------|-------|
| 1 | Roadmap reorganised | Done | Completed sections removed, since the CHANGELOG is the record. Remaining work planned as 0.8.3 → 1.0.0 |
| 2 | Cross-target build check (aarch64) | Done | Builds, and renders all 14 `--ppm` frames byte-identical to x86_64 under `qemu-aarch64`. The check found two defects, both fixed. A local `SYS_LSEEK = 8` overrode the stdlib's: on aarch64, 8 is `getxattr`, so the `/dev/fb0` present path stopped updating after its first frame. A local `O_NOFOLLOW` reached the kernel as `O_LARGEFILE`, which silently dropped the 0.6.3 symlink refusal. `src/engine.cyr` now takes its syscall numbers and open flags from `lib/syscalls.cyr`, and the x86_64 build is behaviourally unchanged |
| 3 | CI: `cyrius fmt --check` hard gate | Done | Held back while three files failed fmt. `src/` and `tests/` are clean now |
| 4 | CI: aarch64 cross-build gate | Done | Fails on the compiler's "conflicting value" and "raw syscall" warnings. Mutation-checked: it fails on the 0.8.1 `engine.cyr` and passes on 0.8.2 |
| 5 | Doc drift | Done | `CLAUDE.md` line counts, README architecture counts |

**Exit criteria**: clean build + lint + fmt + aarch64 gate + 52 assertions across 4 suites. All 14 frames must be byte-identical to 0.8.1 on x86_64 (with and without `scores.dat`) and to x86_64 on aarch64. **Met.**

## v0.8.3 — P(-1) Audit, Refactor, Hardening & Optimization Sweep

A full pass over `src/`, run the 0.6.3 way:
- Every finding is reproduced (a failing test or a measured repro) before it is fixed.
- Every fix is covered by a test or a byte-identical render check.
- Paths CI cannot reach are mutation-checked.

| # | Lens | Scope | Status |
|---|------|-------|--------|
| 1 | Correctness | All six games + engine: state reset between runs, game-over → restart → menu paths, tick math, collision edge cases, score and timer overflow | Pending |
| 2 | Memory safety | Every load/store with a computed index: grid accessors, A* arrays, bullet and enemy pools, framebuffer writes near the edges, `draw_number`. Also any function-local array (only `input.cyr` `buf[4]` is known and safe; a local `var X[N]` reserves one 8-byte slot) | Pending |
| 3 | Security / input hardening | Absorbs the old "deep security audit" item. The main surface is the `input.cyr` escape-sequence parser: partial, unknown and back-to-back sequences, EOF, non-tty stdin. Also the `scores.dat` read path (short, oversized or garbage file; the clamp exists), the `/proc/self/cmdline` parse, and `/dev/fb0` geometry from an untrusted driver | Pending |
| 4 | Refactor and dead code | Battle Tanks has duplicated player/AI shot updaters; merge them. `ai_find_direction` (open-grid A*) and `ai_chase_direction` have no callers, while README and CLAUDE.md say Grid Bugs pursues by shortest path: wire them up or remove them. `main.cyr` is the largest file (1,141 lines); candidates to split out are bitmap text, scores and screenshot mode. `src/test.cyr` is an assertion-free `[build].test` entry that makes bare `cyrius test` report 5 suites against 4 | Pending |
| 5 | Optimization + frame-time benchmarks | First benchmark harness: `benches/*.bcyr`, which `cyrius bench` and `cyrius audit` already look for. Measure per-game update + render time against the <4 ms frame target. CLAUDE.md asks for per-game frame times in the CHANGELOG, and none has ever been recorded. Known lead: each A* call clears five 4,800-slot arrays with the stdlib `memset`, which is a byte loop | Pending |
| 6 | Robustness | Terminal restored on every exit path (Q, Ctrl+C, error). Behaviour with no `/dev/fb0`, no tty, or an unusually small or large panel | Pending |
| 7 | Regression net | The committed screenshots were captured without `scores.dat`, so `draw_number` is invisible to them, and 0.6.3 found a live bug hiding there. Add a with-scores reference set. CI's smoke test checks only the splash file size; compare all 14 frames | Pending |

**Exit criteria**: clean build + lint + fmt + aarch64 gate, with the suite grown to cover every fix. All 14 frames must stay byte-identical except where a fix legitimately changes one; that screenshot is regenerated and called out in the CHANGELOG. Per-game frame times recorded.

## v0.8.4 — Play-Test & Difficulty Tuning

The one thing the headless suite cannot do. This release is user-driven, on a real Linux console (`/dev/fb0`).

| # | Item | Status | Notes |
|---|------|--------|-------|
| 1 | Hands-on pass, all six games on real `/dev/fb0` | Pending | Live input, feel, difficulty, frame pacing |
| 2 | Battle Tanks pacing | Pending | Since 0.7.0 the player moves at the same 15 cells/s as the AI and its shells. It may want a different `tk_tick_rate` or a separate movement rate |
| 3 | MCP Cone attempts | Pending | Three attempts is a first guess, not a measured curve |
| 4 | Disc Arena AI | Pending | The AI has dodged since 0.6.3 and has never been played against |
| 5 | Fix what play-testing surfaces | Pending | Triage each find into this release or 0.9.0 |

## v0.9.0 — Release Candidate

| # | Item | Status | Notes |
|---|------|--------|-------|
| 1 | `cyrius audit` clean, then gated in CI | Pending | Only the docs check fails today: 80 undocumented public functions. fmt, lint and tests already pass, and bench passes once 0.8.3 adds a `.bcyr` |
| 2 | aarch64 on real hardware | Pending | It builds and renders correctly under qemu, but the `/dev/fb0` present path and raw-mode input have never run on real aarch64. Then decide whether `release.yml` ships an aarch64 binary |
| 3 | Docs final | Pending | README (controls, line counts, screenshots if any frame changed in 0.8.x), CLAUDE.md, SECURITY.md checked against what 0.8.3 found |
| 4 | Release-candidate fixes | Pending | As 0.9.x patch releases |

## v1.0.0 — Release

First non-prerelease tag; `release.yml` marks every `0.x` tag as a prerelease. It ships once 0.9.x clears: play-test, sweep and audit done, and CI green on every gate.

## Future (separate repos, separate scope)

| Phase | What | Requires | Notes |
|-------|------|----------|-------|
| **MCP Voice** | Announcer with digital vocal processing | shravan, naad | Pitch down + vocoder + reverb + ring mod. David Warner-style 80s digitized voice. Needs shravan/naad ported first. |
| **Disc Wars** | Full 3D arena disc combat | kiran, impetus | Disc Arena (2D) ships in v1.0; 3D version is a separate effort |
| **THE GRID** | Interactive world, AI programs, two visual modes | kiran, joshua, impetus | The big one. 1982 wireframe + modern. |
