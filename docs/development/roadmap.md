# ENCOM's Hits — Development Roadmap

> **Status**: v0.8.3 (Cyrius 6.7.18 toolchain) — pre-1.0 hardening | **Last Updated**: 2026-11-07

This file tracks only what is left. Shipped work, release by release, is recorded in
[CHANGELOG.md](../../CHANGELOG.md).

**Where things stand:** all six games are complete and playable with AI, scoring and
persistent high scores, on one shared engine: framebuffer with `/dev/fb0` blit, Bresenham
drawing, raw-mode input, glow, A*, and maze generation. The road to 1.0.0 is confidence
work, not features. No new games.

| Release | Theme | State |
|---------|-------|-------|
| v0.8.3 | P(-1) sweep: audit, refactor, hardening, optimization, repair | **Current** |
| v0.8.4 | Play-test, difficulty tuning and the design calls 0.8.3 found | Next |
| v0.9.0 | Release candidate: `cyrius audit` clean, aarch64 on hardware, docs final | Planned |
| v1.0.0 | Release | Target |

---

## v0.8.3 — P(-1) Audit, Refactor, Hardening & Optimization Sweep (current)

Done; see the CHANGELOG for detail. Run the 0.6.3 way: every finding reproduced first (a failing test, or end to end against the 0.8.2 binary on a pseudo-terminal), every fix covered, every refactor shown to change no behaviour.

| # | Lens | Outcome |
|---|------|---------|
| 1 | Correctness | Light Cycles arrows steered the AI's cycle; Light Cycles' packed step only worked by luck off the edges; the font lacked J/Q/V/Z ("TO UIT", "GAME O ER"). Fixed. Game-design findings moved to 0.8.4 |
| 2 | Memory safety | Every computed index walked: no live defect. The maze RNG's `INT64_MIN` path was checked and is unreachable. `engine_init` alloc failure and the initial `_fb_fd = 0` were hardened |
| 3 | Security / input hardening | New escape-sequence parser: F-keys and modified arrows no longer leak game keys. Enter works (CR). Input read bounded per frame. Non-tty stdin refused instead of hanging. `--ppm` is matched as a whole argument |
| 4 | Refactor and dead code | `main.cyr` 1,141 → 220 lines (text, scores, screens, play). Tanks shot updaters merged. Dead A*/chase removed; A* arrays sized to the maze (binary −47%). `src/test.cyr` removed |
| 5 | Optimization + benchmarks | `benches/frame.bcyr` added. Every game frame is 23–35% faster (171–750 µs); 1440p blit 3.45 → 2.48 ms |
| 6 | Robustness | Terminal restored on fatal signals (HUP/INT/QUIT/TERM/ILL/ABRT/BUS/FPE/SEGV), then re-raised |
| 7 | Regression net | `tests/frames.sh` checks all 28 frames (14 with and 14 without a fixture `scores.dat`) in CI. 8 suites, 160 assertions (was 4 and 52) |

**Exit criteria**: clean build, lint, fmt, aarch64 gate, all suites green, 28 frames matching, per-game frame times recorded. **Met.**

## v0.8.4 — Play-Test, Difficulty Tuning & Design Calls

The one thing the headless suite cannot do. This release is user-driven, on a real Linux console (`/dev/fb0`). The 0.8.3 sweep found several behaviours that are design decisions rather than bugs; they are settled here, alongside the play-test.

| # | Item | Status | Notes |
|---|------|--------|-------|
| 1 | Hands-on pass, all six games on real `/dev/fb0` | Pending | Live input, feel, difficulty, frame pacing. First real-console run of the 0.8.3 parser, signal restore and the faster blit |
| 2 | Battle Tanks pacing | Pending | Since 0.7.0 the player moves at the same 15 cells/s as the AI and its shells. It may want a different `TK_TICK_RATE` (`play.cyr`) or a separate movement rate |
| 3 | MCP Cone attempts | Pending | Three attempts is a first guess, not a measured curve |
| 4 | Disc Arena AI | Pending | The AI has dodged since 0.6.3 and has never been played against |
| 5 | Scoring that varies | Pending | Battle Tanks and Disc Arena can only ever score 0 or 1000 (a win always takes exactly 5 Disc hits), so their high scores are binary. The same class of defect as MCP Cone's constant 1800, fixed in 0.7.0 |
| 6 | MCP Cone shot steering | Pending | The shot is drawn and hit-tested at the player's *current* angle, so moving mid-flight steers it through each ring's gap. Decide: a mechanic, or record the angle at fire time |
| 7 | Interceptors threat | Pending | Enemies pass through the ship harmlessly, one leaving the bottom costs nothing, and difficulty stops rising at wave 5 (8 enemies) |
| 8 | Grid Bugs pursuit | Pending | Every bug runs the same greedy x-then-y step, so they merge into a single stack within seconds. Vary the pursuit (axis preference, a scatter phase) |
| 9 | M and N glyphs | Pending | The 3x5 font draws M and N alike, so the title reads as "EMCOM". Changing either glyph changes most reference frames |
| 10 | Console cursor over the game | Pending | The game never switches the tty to graphics mode (`KDSETMODE`), so fbcon may draw its cursor or console text over the frame. Check on the real console. None of the sister repos (cyrius-doom, -polyomino, -bb) switches modes either, so there is no reference fix; any mode switch must be undone on every exit path, signals included |
| 11 | Fix what play-testing surfaces | Pending | Triage each find into this release or 0.9.0 |

## v0.9.0 — Release Candidate

| # | Item | Status | Notes |
|---|------|--------|-------|
| 1 | `cyrius audit` clean, then gated in CI | Pending | Only the docs check fails: 103 undocumented public functions, 69 in `src/` (75 at 0.8.2) and 34 test and bench helpers. Settle whether helpers in `tests/` and `benches/` need doc comments. fmt, lint, tests and bench pass |
| 2 | aarch64 on real hardware | Pending | It builds and renders correctly under qemu, but the `/dev/fb0` present path and raw-mode input have never run on real aarch64. Then decide whether `release.yml` ships an aarch64 binary |
| 3 | High scores location | Pending | `scores.dat` is read and written in the current directory, so the high scores depend on where the game was launched. Decide whether to move them (for example under `$XDG_DATA_HOME`) before 1.0.0 fixes the format |
| 4 | Present path | Pending | At 1440p the blit (2.5 ms) plus the kernel's copy of a 14.7 MB band is the largest per-frame cost. A `writev` of one row per scaled line would drop the replication copies, but needs per-arch syscall numbers and a real-hardware check (the aarch64 gate would not catch a wrong one) |
| 5 | Docs final | Pending | README, CLAUDE.md, SECURITY.md checked against what 0.8.4 changes |
| 6 | Release-candidate fixes | Pending | As 0.9.x patch releases |

## v1.0.0 — Release

First non-prerelease tag; `release.yml` marks every `0.x` tag as a prerelease. It ships once 0.9.x clears: play-test, sweep and audit done, and CI green on every gate.

## Future (separate repos, separate scope)

| Phase | What | Requires | Notes |
|-------|------|----------|-------|
| **MCP Voice** | Announcer with digital vocal processing | shravan, naad | Pitch down + vocoder + reverb + ring mod. David Warner-style 80s digitized voice. Needs shravan/naad ported first. |
| **Disc Wars** | Full 3D arena disc combat | kiran, impetus | Disc Arena (2D) ships in v1.0; 3D version is a separate effort |
| **THE GRID** | Interactive world, AI programs, two visual modes | kiran, joshua, impetus | The big one. 1982 wireframe + modern. |
