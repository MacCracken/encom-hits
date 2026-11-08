# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

## [0.8.3] — 2026-11-07

The P(-1) sweep: a full pass over `src/` for correctness, memory safety, input hardening, dead code, performance, robustness and regression cover. Every fix below was reproduced first: as a failing test, or end to end against the 0.8.2 binary on a pseudo-terminal. Every refactor was shown to change nothing. Most of the defects were in keyboard input, and none could be seen in the headless `--ppm` frames.

### Fixed
- **Enter did nothing on a real terminal.** Raw mode clears `ICRNL`, so the Enter key arrives as CR (13), but only LF (10) was mapped, and the menu's "ENTER TO SELECT" never worked. Games could only be started with the number keys. CR is now Enter, and LF still is.
- **Function keys and modified arrows leaked game commands.** The parser read ESC plus exactly two more bytes and mapped only `ESC [ A..D`, so every other sequence spilled its remaining bytes into the key map:
  - From the menu, F5 launched Interceptors (it sent '5'), and F10, F11 and F12 launched games 1, 3 and 4.
  - Shift+Down launched Grid Bugs (it sent '2').
  - The trailing letter of any modified arrow read as a WASD key.

  `input.cyr` now has a proper byte-at-a-time parser. It consumes CSI sequences whole, SS3 sequences (application-cursor mode) and the Linux console's F1–F5. A final A/B/C/D is an arrow whatever its modifiers; anything else is ignored. A lone ESC is held one frame in case the rest of a sequence is still in transit, and an unfinished sequence is dropped after that, so a stray `ESC [` cannot swallow later keys.
- **Light Cycles: the arrow keys steered the AI's cycle.** Player 2 is always the AI, but the arrows set its direction one line before the AI chose. `ai_lightcycles` keeps its current direction when that leaves at least half of its best open run, so one player could steer both cycles and drive the opponent into walls. The arrows now steer player 1, as they do in every other game.
- **The terminal was left raw after a kill, a closed terminal or a crash.** Raw mode clears `ISIG`, so only the in-game Q/Ctrl+C path restored the terminal. After SIGTERM, SIGHUP or a SIGSEGV you had no echo and no line editing until you typed `reset` blind. Handlers for HUP, INT, QUIT, TERM, ILL, ABRT, BUS, FPE and SEGV now restore the original termios. Then they re-raise the signal, so the exit status and any core dump are unchanged. SIGKILL still cannot be caught.
- **Stdin that is not a terminal hung the game.** With stdin an open pipe, the first `read` blocked forever: VMIN/VTIME only apply to ttys, so not one frame was drawn. With a file or `/dev/null` the game ran, but nothing could control it. It now refuses to start, says why, and exits 1. `--ppm` needs no terminal.
- **Input could hold a frame open indefinitely.** `input_poll` read one byte per syscall until the tty ran dry, so input arriving faster than it was consumed kept the frame from finishing. Now there is one read per frame of at most 64 bytes, and the rest waits for the next frame.
- **"PRESS ANY KEY" accepted only Enter, Space, Esc and 1–4.** Any key now skips the splash.
- **The font had no J, Q, V or Z, and a missing glyph draws nothing.** The menu footer read "TO UIT", every "GAME OVER" card read "GAME O ER", and MCP Cone's loss card read "DERE  ED". All four glyphs were added. `screenshots/menu.png` is the only reference frame that changed.
- **`--ppm` matched anywhere in `/proc/self/cmdline`, argv[0] included.** So `--ppmx`, or a binary run from a path containing `--ppm`, took screenshot mode. It must now be a whole argument.
- **`engine_init` failure paths:**
  - When the framebuffer allocation failed, `main` drew through a null pointer. It now exits 1 with a message.
  - The PPM buffer's allocation was never checked.
  - `_fb_fd` started at 0, which is stdin, so a shutdown before init would have closed it.

### Changed
- **`main.cyr` split, 1,141 → 220 lines.** The new modules:
  - `text.cyr`: the bitmap font.
  - `scores.cyr`: the high-score file.
  - `screens.cyr`: splash, menu, title and result cards.
  - `play.cyr`: per-game input and ticks, and `play_frame`.

  Only one game runs at a time, so one `play_ticks`/`play_done` pair replaces 18 per-game tick globals. `play_frame` owns ESC-to-menu, which had been written out twice in each of the six game ticks. One `_result_card` draws all six result screens, and one `_menu_row` draws the six menu rows.
- **Battle Tanks: one shot updater.** The player's and the AI's updaters were the same 50 lines twice. The latched-move code moved from `main.cyr` into `tanks.cyr`.
- **Light Cycles: the step no longer round-trips through `x * 1000 + y`.** A step off the left or top edge decoded to garbage coordinates that only happened to read as a wall.
- **`ai.cyr` lost its dead code:** the open-grid A* (`ai_find_direction`) and `ai_chase_direction` had no callers, 145 lines in all. Grid Bugs keeps its greedy chase, which is already a shortest path on its fully open grid. The A* working arrays were sized for the 4,800-cell Light Cycles grid they never ran on; they now hold the 192-cell tank maze. That is 184,320 bytes less static data, and the binary went from 402,632 to 214,616 bytes (−47%; aarch64 451,640 → 267,704).
- **`src/test.cyr` and the `[build].test` entry were removed.** The file held no assertions and made bare `cyrius test` report 5 suites against 4.
- **`engine_layout()` was split out of `engine_probe_fb`.** The blit test now runs the real geometry formula instead of a hand copy.

### Performance
- **Every draw primitive writes a pixel as one 32-bit store** instead of four byte stores. These are the same four bytes, so the output is byte-identical.
- **The glow pass walks a pointer along each row** instead of recomputing the offset per pixel, and updates each neighbour with one 32-bit load and store instead of three byte loads and three byte stores.
- **`engine_blit`** writes two 32bpp pixels per 64-bit store and copies replicated rows 32 bytes per pass.
- **A\*** clears two arrays with word stores, instead of five with the byte-loop stdlib `memset`.
- Frame times, from `cyrius bench benches/frame.bcyr`. Each figure is the median of three interleaved runs per tree on the test machine; absolute numbers move about ±10% from run to run. A "frame" is that game's render plus glow over a busy mid-run state.

  | Benchmark | 0.8.2 | 0.8.3 | Change |
  |---|---:|---:|---:|
  | Light Cycles frame | 989 µs | 750 µs | −24% |
  | Grid Bugs frame | 623 µs | 467 µs | −25% |
  | Battle Tanks frame | 426 µs | 307 µs | −28% |
  | MCP Cone frame | 429 µs | 310 µs | −28% |
  | Interceptors frame | 261 µs | 171 µs | −35% |
  | Disc Arena frame | 294 µs | 203 µs | −31% |
  | Glow on a black frame (fixed cost) | 217 µs | 142 µs | −34% |
  | Tanks A* search, corner to corner | 86 µs | 75 µs | −13% |
  | Light Cycles lookahead | 0.9 µs | 0.9 µs | — |
  | `engine_blit`, 2560×1440 panel | 3.45 ms | 2.48 ms | −28% |

  Every game's own work fits well inside the 4 ms target. The `/dev/fb0` present path is now the largest per-frame cost on a 1440p panel. Two further gains were measured and not taken: inlining the glow neighbour update would save another ~11%, but readability won; and the open-set scan dominates A*, which runs only once per tank tick.

### Added
- **`benches/frame.bcyr`**, the project's first benchmarks: per-game frames, glow, both AI hot paths and the 1440p present path. It includes only game modules, so it also builds against older trees for before/after comparisons. CI runs it as an informational step.
- **`tests/frames.sh` and `tests/frames.sha256`.** The script renders all 14 `--ppm` frames twice, once with no `scores.dat` and once with a fixture `scores.dat`. The fixture makes `draw_number` draw every digit and exercises both load clamps. All 28 frames are checked against the manifest. It replaces CI's smoke test, which only checked the splash file's size. Run `sh tests/frames.sh build/encom-hits --update` after an intended render change.
- **Four new suites:**
  - `input-parser`: 40 assertions.
  - `play`: 23.
  - `tanks-shots`: 25, covering the merged updater, the bounce limit and A*.
  - `font`: 12.

  `engine-blit` grew from 4 to 13 assertions: it covers scales 1, 2, 3, 4 and 6 at 16 and 32bpp with padded pitches, checking every panel pixel. Until now it only covered scale 1, where the row copy never runs. The total is 8 suites and 160 assertions (was 4 and 52), and every new suite was mutation-checked.
- **The CI fmt gate covers `benches/`.** `.gitignore` lists `/scores.dat`.

### Notes
- **Refactors were shown to change nothing.** A scratch harness, not committed, drove all six games through their public APIs, and the full play layer one frame at a time, with seeded scripted input. It hashed every rendered frame and the game state. The game-layer trace is identical to 0.8.2, and so is the play-layer trace once the two intended changes (the Light Cycles arrows and the four glyphs) are reverted. The harness was itself mutation-checked.
- **End to end:** the real binary ran on a pseudo-terminal inside a user namespace, with `/dev/fb0` bind-mounted to `/dev/null`, so nothing reached the screen. Against 17 checks, 0.8.2 fails 9 and 0.8.3 passes all 17, on x86_64 and on aarch64 under qemu.
- **Found, and left for the 0.8.4 play-test (game-design calls):**
  - Battle Tanks and Disc Arena can only ever score 0 or 1000.
  - MCP Cone's shot follows the player's angle mid-flight.
  - In Interceptors, enemies pass through the ship, leaving the screen costs nothing, and difficulty stops rising at wave 5.
  - Grid Bugs' identical greedy pursuit merges every bug into one.
  - The font draws M and N alike, so the title reads as "EMCOM".
- **The aarch64 gate catches less than 0.8.2 said.** `syscall(20, …)` (x86_64 `writev`) built for aarch64 with no warning and ran as `epoll_create1`. A new raw syscall number still needs a `qemu-aarch64 -strace` check by hand; the CI comment now says so.
- **Checked and not a bug:** the maze RNG's `0 - x` cannot reach `INT64_MIN`, which would make a negative pick index. The only state that steps to it is negative, and stored states never are.
- **`scores.dat` is tracked in git.** It has been since a 0.6.x commit, and holds play-test scores. It is now in `.gitignore`, but stays tracked until it is removed from the index (`git rm --cached scores.dat`). Nothing in CI reads it any more.

## [0.8.2] — 2026-11-07

Quick-wins release. Clears the open roadmap items that needed neither a design decision nor a play-test, and reorganises what is left into 0.8.3 → 1.0.0. The cross-target check turned up two real aarch64 defects. No game-logic or render changes.

### Fixed
- **aarch64: the `/dev/fb0` present path stopped updating after the first frame.** `src/engine.cyr` declared its own `SYS_LSEEK = 8`. A local definition overrides the stdlib's (the compiler: "last definition wins"), and on aarch64, 8 is `getxattr`. Under `qemu-aarch64 -strace` every frame issued `getxattr(3, NULL, NULL, 96) = -EFAULT`, so the file offset was never rewound. The first full-panel write succeeded, and every later one failed with `ENOSPC` because the offset sat at the end of the device. On real aarch64 hardware the display would have frozen on the splash's first frame.
- **aarch64: `O_NOFOLLOW` was silently dropped on every file the game opens.** The local `O_NOFOLLOW = 131072` (x86_64 `1 << 17`) is `O_LARGEFILE` on aarch64. So the symlink refusal added in 0.6.3 did not exist there. Reproduced under qemu with `scores.dat` symlinked to another file: the 0.8.1 aarch64 build opened it as `O_RDONLY|O_LARGEFILE` and read all 48 bytes through the link. The fixed build gets `ELOOP`. The 14 `/tmp` PPM writes now carry `O_NOFOLLOW` as well. No shipped binary was affected, because `release.yml` has only ever built x86_64.
- **Root cause, fixed once:** `src/engine.cyr` carried private x86_64 copies of `SYS_READ`, `SYS_WRITE`, `SYS_CLOSE`, `SYS_IOCTL`, `SYS_NANOSLEEP`, `SYS_LSEEK`, `CLOCK_MONOTONIC` and the five `O_*` flags. All twelve are gone, and the file now uses the stdlib's per-target values from `lib/syscalls.cyr`. Only `SYS_OPEN` and `SYS_CLOCK_GETTIME` stay local, because the stdlib does not define them on every target. The aarch64 backend's syscall translation maps both x86_64 numbers (open → `openat(AT_FDCWD, …)`, 228 → `clock_gettime`), confirmed with `qemu-aarch64 -strace`.

### Added
- **CI: `cyrius fmt --check` hard gate** over `src/` and `tests/`. It was held back while three files failed fmt, and everything has been canonically formatted since the 0.7.1 reflow. The step was checked to exit 1 on a misformatted file.
- **CI: aarch64 cross-build gate.** It runs `cyrius build --aarch64` and fails on the compiler's `conflicting value` and `raw syscall` warnings, the two that mean "this target gets a different syscall or flag than you wrote". It is build-only: the binary is neither run nor shipped. Mutation-checked: replayed against the 0.8.1 `engine.cyr`, it fails and lists all eight defects; against 0.8.2 it passes.

### Changed
- **`cyrius.cyml` lists `syscalls` in `[deps].stdlib`**, because the game now depends on its constants directly. This changes nothing in the vendored closure (still 19 files, and `cyrius.lock` is unchanged): `alloc` and `assert` already included it. The manifest comment that explained the old private enum was rewritten.
- **Roadmap reorganised.** Completed sections were removed, since this file is the record. The remaining work is planned as:
  - **0.8.3:** P(-1) audit, refactor, hardening and optimization sweep.
  - **0.8.4:** play-test and difficulty tuning.
  - **0.9.0:** release candidate.
  - **1.0.0:** release.
- **Doc drift:** `CLAUDE.md` said each game was 200–300 lines and the collection ~3.9K. It is 226–315 and ~4.4K. README's architecture counts were updated for the shorter `engine.cyr`.

### Notes
- **x86_64 is behaviourally unchanged.** Every removed constant had the same value as the stdlib's x86_64 one. The `--ppm` syscall trace (`qemu-x86_64 -strace`, addresses normalised) is identical to 0.8.1 apart from the `/proc/self/cmdline` length, which differs only because the binaries live at different paths. All 14 frames are byte-identical to 0.8.1, both with and without `scores.dat`. Lint, fmt and all 52 assertions across 4 suites pass.
- **aarch64 now matches x86_64.** Under `qemu-aarch64`, all 14 frames are byte-identical to the x86_64 frames in both `scores.dat` modes. A probe built with the same constants shows `lseek(3, 3, SEEK_SET) = 3`.
- Binary 402,728 → 402,632 bytes (−96), and static data 253,720 → 253,624. That is exactly twelve 8-byte slots, one per removed duplicate constant.

## [0.8.1] — 2026-11-07

Toolchain and stdlib refresh onto Cyrius 6.7.18. No game-logic or render changes. One CI fix was required.

### Changed
- **Toolchain `6.7.9` → `6.7.18`** — `cyrius.cyml` `[package].cyrius`. CI and release read the pin by grep, so the install step needed no workflow edit.
- **Vendored stdlib and `cyrius.lock` re-synced to the 6.7.18 bundle.** `cyrius deps` regenerated `lib/` from `~/.cyrius/versions/6.7.18/lib`, and all 19 files match the bundled copies byte for byte. The closure is the same 19 files. Of the 13 files that changed, only three are compiled on x86_64 Linux:
  - **`syscalls_x86_64_linux`:** a named `SYS_POLL = 7` (6.7.14), plus `EPOLL_EVENT_SIZE` and the `epoll_event_*` accessors.
  - **`syscalls_linux_common`:** `fd_wait_ready` and its siblings now issue `SYS_POLL` instead of a bare `7`. There are also macOS-only arms for `mknodat` and `sigprocmask`.
  - **`vec`:** the six bounds, overflow and allocation abort paths now go through a single `_vec_abort`, with an optional `_vec_die_hook` called first.

  encom never calls any of these. None of the new names (`SYS_POLL`, `EPOLL_*`, `epoll_event_*`, `_vec_abort`, `_vec_die_hook`) appears in `src/` or `tests/`, so nothing collides with encom's own `SYS_*` enum. The other ten files are either comment-only or apply to targets that are never compiled here: Windows, agnos, macOS, aarch64, and the cyrius-x allocator.

### Fixed
- **CI's Test step called a command that no longer exists.** `cyrius tests` was removed in Cyrius 6.7.12 ("use `cyrius test <dir>`"), so at the new pin the step printed only that error. Its `, 0 failed` check would then have failed the job. The step now runs `cyrius test tests`. The output format is unchanged (one line per suite, then `N passed, 0 failed`), so the existing summary and suite-count checks work as they are, and they pass locally at 4 suites. The directory is named on purpose. Bare `cyrius test` also counts the assertion-free `[build].test` entry (`src/test.cyr`), which would report 5 suites against 4 `.tcyr` files. The step's comment, which still described the 0.6.3 suite list, now names all four suites.
- **`CONTRIBUTING.md` ran only one of the four suites.** Its build block had `cyrius test tests/encom-hits.tcyr`; it now runs `cyrius test tests`.

### Notes
- Verified at the new pin: clean `cyrius deps` + build with no new warnings, `cyrius test tests` 52 assertions across 4 suites, lint clean on all of `src/`, and `--ppm` rendering all 14 screens (splash 230,415 bytes).
- **Render is byte-identical to the 6.7.9 build** in all 14 frames, both with no `scores.dat` (where the frames are also `magick compare -metric AE` = 0 against `screenshots/*.png`) and with a non-zero `scores.dat`, which exercises `draw_number` on the menu and all six title cards.
- No frame-time benchmark this release. The stdlib calls the game makes at runtime (`alloc`, `memset`, `memcpy`) are unchanged from 6.7.9.
- **Binary 406,808 → 402,728 bytes (−4,080), and all of it comes from the compiler.** Building with the 6.7.18 compiler against the old 6.7.9 stdlib gives the same 402,728 bytes, so the stdlib changes are size-neutral. Static data went 253,704 → 253,720 and unreachable functions 252 → 256.

## [0.8.0] — 2026-11-07

Moves onto the Cyrius 6.7.x toolchain line. No game-logic or render changes.

### Changed
- **Toolchain `6.6.20` → `6.7.9`** — `cyrius.cyml` `[package].cyrius`. CI and release read the pin by grep, so the install step needed no workflow edit.
- **Vendored stdlib and `cyrius.lock` re-synced to the 6.7.9 bundle.** `cyrius deps` regenerated `lib/` from `~/.cyrius/versions/6.7.9/lib`, and all 19 files match the bundled copies byte for byte. The closure is the same 19 files as 0.7.2. Thirteen of them changed, mostly in comments: internal advisory IDs (`CVE-nn` → `CYRIUS-2026-nnnn` or a plain description), plus a header note that the bootstrap compiler builds these files. The code changes are:
  - **`sys_ppoll` / `SYS_PPOLL = 271`** (6.7.9), in `syscalls_x86_64_linux` and `syscalls_linux_common`. encom declares its own `SYS_*` enum in `src/engine.cyr`, and that enum has no `SYS_PPOLL`, so nothing collides. The wrapper is never called here.
  - **`fnptr`:** indirect calls with 7 or 8 arguments now pass them in the order a Cyrius callee reads them; arguments 7 and 8 used to arrive swapped. encom makes no `fnptr` calls. The file is vendored only because `vec` and `alloc` include it.
  - **macOS, Windows, agnos and aarch64 syscall files:** each gains its `sys_ppoll` entry or stub, plus some annotations and cleanup. None of these files is compiled on an x86_64 Linux build.

### Notes
- Verified at the new pin: clean `cyrius deps` + build with no new warnings, `cyrius tests` 52 assertions across 4 suites, lint clean on all of `src/`, and `--ppm` rendering all 14 screens (splash 230,415 bytes).
- **Render is byte-identical to the 6.6.20 build** in all 14 frames, both with no `scores.dat` (where the frames are also `magick compare -metric AE` = 0 against `screenshots/*.png`) and with a non-zero `scores.dat`, which exercises `draw_number` on the menu and all six title cards.
- No frame-time benchmark this release. The stdlib functions the game calls at runtime (`alloc`, `alloc_init`, `memset`, `memcpy`, `strlen`) are unchanged from 6.6.20.
- Binary size is unchanged at 406,808 bytes, but the contents differ: code offsets shift around the new dead `sys_ppoll`. Static data is unchanged at 253,704 bytes, and unreachable functions went 251 → 252.

## [0.7.2] — 2026-11-07

Toolchain and stdlib refresh onto Cyrius 6.6.20. No game-logic or render changes.

### Changed
- **Toolchain `6.6.2` → `6.6.20`** — `cyrius.cyml` `[package].cyrius`. CI and release read the pin by grep, so the install step needed no workflow edit.
- **Vendored stdlib re-synced to the 6.6.20 bundle.** `cyrius deps` regenerated `lib/` from `~/.cyrius/versions/6.6.20/lib`, and every vendored file now matches the bundled copy byte for byte. `[deps].stdlib` is unchanged, but the closure grew 17 → 19 files: `alloc` now includes `poison` (allocator poison mode, 6.6.18) and `alloc_cx` (the cyrius-x bytecode allocator, 6.6.6). Both includes sit behind `#ifdef` (`CYRIUS_POISON` / `CYRIUS_TARGET_CX`), which this build never defines, so they compile to nothing here. `string` now includes `alloc` itself, which is harmless because includes are include-once.

### Added
- **`cyrius.lock`.** On 6.6.20, `cyrius deps` writes a lockfile for stdlib-only projects too (6.6.2 wrote none). It records a sha256 for each vendored `lib/` file plus the toolchain version, and is tracked next to `cyrius.cyml`, the same way cyrius-polyomino does it. CI still runs bare `cyrius deps` with no `--verify`.

### Fixed
- **CHANGELOG ordering.** The 0.7.1 entry and the `[Unreleased]` heading had been appended below 0.6.0 at the foot of this file. Both now sit at the top in release order.
- **Documentation drift left by 0.7.1.** That release moved the pin without the docs, so README's toolchain floor, `CLAUDE.md`'s version, the roadmap status line, and the two constant-fold `NOTE:` comments in `src/engine.cyr` / `src/draw.cyr` still said 6.5.36 / 0.7.0. The `NOTE:` comments now say "the pinned toolchain" so they stop going stale on every bump. The `cyrius.cyml` and CI comments about the vendored closure and the lockfile are also current.

### Notes
- Verified at the new pin: clean `cyrius deps` + build with no new warnings, `cyrius tests` 52 assertions across 4 suites, lint clean on all of `src/`, and `--ppm` rendering all 14 screens (splash 230,415 bytes).
- **Render is byte-identical to the 6.6.2 build** in all 14 frames, in both cases tested:
  - With no `scores.dat`, the frames are also `magick compare -metric AE` = 0 against `screenshots/*.png`.
  - With a non-zero `scores.dat`, the frames exercise `draw_number` on the menu and all six title cards.
- No frame-time benchmark this release. The stdlib calls the game makes at runtime (`alloc`, `memset`, `memcpy`) are unchanged in 6.6.20 apart from the compiled-out poison arms. The per-frame hot paths (`draw_clear`, `engine_blit`, `glow_apply`) are hand-rolled word loops that never call into the stdlib.
- Binary 393,984 → 406,808 bytes (+12,824); static data 253,240 → 253,704; unreachable functions 208 → 251. All of this growth is the larger stdlib carried as dead code. No game code changed.

## [0.7.1] — 2026-09-11

### Changed

- **Toolchain `6.5.36` → `6.6.2`.** No source change; the value form needed none.
  Build, tests, and any bench/fuzz/distlib target the repo ships re-verified at the new pin.

## [0.7.0] — 2026-08-31

Game-feel release. The 0.6.3 audit surfaced six defects that were deliberately
held back because each changes how a game plays rather than whether it is
correct; this release takes all six, plus the paddle clamp left over from the
same sweep. Minor rather than patch: Battle Tanks controls, Light Cycles
head-on outcomes, and MCP Cone scoring all change observably.

### Fixed
- **Battle Tanks: the player outran the entire simulation.** `tk_handle_input` performed a full grid-cell move on every frame it saw a key flag, while AI movement and every projectile step advanced once per `tk_tick_rate` (4) frames. The tank therefore moved at the terminal's key-repeat rate — roughly 25–30 cells/s against a 15 cells/s world — so the player crossed the 16-cell maze in about half a second, could drive away from an incoming shot indefinitely (the shot literally could not catch up), and the AI could never close. A two-key frame also produced a diagonal step, because the four direction blocks each acted independently. Input now *latches* a direction (the turret still turns every frame, so aiming stays responsive) and `tk_apply_pending_move` applies exactly one cell on one axis inside the tick block.
- **Battle Tanks: the AI walked onto the player and froze there.** Its A* goal is the player's exact cell, and `ai_find_direction_maze` returns `DIR_NONE` once start equals goal — so against a stationary player the AI arrived, stopped permanently, and (being drawn second) its orange square completely hid the player's cyan one. The AI now refuses the last step, staying adjacent and facing the player so it keeps firing down the right line.
- **Battle Tanks: point-blank shots passed through their target.** Both projectile updaters advanced to the next cell *before* testing for a hit, so an enemy standing on the shot's own cell was a blind spot. Each updater now tests its current cell before advancing.
- **Light Cycles: head-on collisions were decided by update order and always killed Player 2.** A cycle's head cell was never written into `lc_grid` — only the cell it vacated — and P1 was updated in full before P2. A symmetric head-on therefore resolved as P1 stepping *through* P2's head (that cell reads 0) and P2 then dying on the trail P1 had just laid; the explicit same-cell test never fired because the heads swapped rather than coincided. A human could ram the AI head-on and win on demand. `lc_update` now snapshots both cycles, tests both destinations against the same pre-move grid, and resolves three cases explicitly: same destination, cell-swap, and driving into the cell the opponent is vacating. A head-on is now a draw. This also closes the related case where P1 drove into a cell P2 was leaving and sat inside P2's fresh trail unharmed.
- **Interceptors: every bullet froze for ~1.5 s between waves.** `int_update` returned early while the respawn timer ran, skipping the player-bullet, enemy-bullet and collision loops — but `int_render` kept drawing them, so bullets hung motionless in mid-air and then jumped back into motion. The 4-slot player-bullet pool could not drain either, so a player who kept firing filled it with frozen bullets and the fire button stopped responding. Only the enemy-movement loop is now held between waves; the respawn timer moved to the end of the update.
- **MCP Cone could be won but never lost, and every completed run scored exactly 1800.** The module header has always promised "Get hit = death", but nothing ever cleared `mcp_player_alive`: a destroyed shot cost nothing and `mcp_fire` could retry on the very next frame, so mashing fire always eventually broke all 8 rings. A run now has three attempts, a barrier hit spends one, and running out ends the run with a DEREZZED card. Scoring moved onto `mcp_rings_broken()` — 100 per ring, +1000 only for reaching the core — so a loss still banks progress and the high score varies instead of being a constant. Remaining attempts are drawn as pips in the top-left, because a lose condition the player cannot see is worse than none.
- **Disc Arena: the paddle walked off the arena on the game-over screen.** `disc_handle_input` runs every frame including after the match ends, but the only clamp lived in `disc_update`, which is gated on `disc_game_done`. Holding a movement key on the game-over screen drove `disc_p1_y` past −160 and the paddle vanished. The clamp now lives in the input handler (matching how Interceptors bounds `int_player_x`), and both it and `disc_update` share `disc_min_y()` / `disc_max_y()` so they cannot drift apart.

### Removed
- **`gb_score`, a dead second scoring path in Grid Bugs.** It was initialised, reset, and awarded +1000 for reaching the I/O Tower — and never read by anything. The live award is `main.cyr`'s `game_score += gb_level * 500`. Editing the obvious-looking one inside the game module changed nothing that was displayed or persisted; `main.cyr` is now the single scoring authority.

### Changed
- **CI lint is a hard gate.** The eight over-long tank-input one-liners it used to tolerate disappeared when Battle Tanks movement was rewritten, so `src/` is lint-clean and the gate now holds that line instead of merely reporting it.

### Added
- `tests/lightcycles-headon.tcyr` — 17 assertions over collision resolution: head-on swap and same-cell approaches are draws, the outcome is symmetric under role reversal, driving into a vacated cell kills, diverging cycles both survive and both lay trail, and boundaries and existing trails still kill. Mutation-checked against the 0.6.3 behaviour (6 assertions go red).
- MCP Cone lives and scoring assertions in `tests/mcpcone-rotation.tcyr`, also mutation-checked. The suite total is now 52 assertions across 4 files.

### Notes
- **This release wants play-testing, and the headless suite cannot substitute.** Battle Tanks is the big one: the player now moves at the same 15 cells/s as the AI and its shells, which is a large change to how the game feels and may want a different `tk_tick_rate` or a separate movement rate. MCP Cone's three attempts is a first guess at a difficulty curve, not a measured one. Disc Arena's AI has been dodging since 0.6.3 and still has not been played.
- Render is unchanged except MCP Cone, whose 135 changed pixels are the new lives pips (confirmed confined to x=5..27, y=5..11 — the pip region plus its glow bleed). `screenshots/mcpcone.png` regenerated. The other 13 frames are `magick compare -metric AE` = 0 against the committed art, because the fixes above are behavioural and the reference frames are captured at states they do not alter.
- Binary 393,960 → 393,984 bytes.

## [0.6.3] — 2026-08-31

Priority-1 audit and hardening pass: a six-lens sweep of `src/` (memory safety,
security, game-logic correctness, performance, structure, robustness) with every
acted-on finding independently verified before the fix. Two games were broken as
designed; the display path could not hold 60fps on an ordinary monitor.

### Fixed
- **Stack-frame overflow through function-local arrays — the five sites are now file-scope `.bss`.** On the pinned toolchain a *function-local* `var X[N]` reserves exactly one 8-byte slot regardless of `N` (measured: for locals `var a[2]; var b[2];` and `var a[8]; var b[8];`, `&b - &a` is −8 in both cases), while a file-scope `var X[N]` correctly reserves N slots. encom addresses its local arrays as 8-byte slots via `store64(&X + i*8, …)` / `load64(&X + i*8)`, so every write past index 0 landed outside the reservation and smashed adjacent frame memory. Each site moved to a private file-scope array in its own module, matching the pattern already used for `_ai_g_cost[4800]` and `lc_grid[4800]`:
  - `main.cyr` `draw_number` — `digits[8]` → `_draw_digits[8]`
  - `grid.cyr` `maze_generate` — `cand_dir[4]` → `_maze_cand_dir[4]`
  - `engine.cyr` — the three 16-byte `timespec`s → `_engine_ts[2]` (`engine_tick_begin`), `_engine_now_ts[2]` (`engine_get_time_ns`), `_engine_sleep_ts[2]` (`engine_tick_wait`)

  A single shared static is safe at each site: none of the five functions recurses or runs from a signal handler. The `maze_generate` candidate list is the only one written inside a loop, and it is refilled from index 0 on every iteration and read only below `cand_count`, with the backtracker iterative over an explicit `_maze_stack` rather than recursive.
- **Menu and title-card high scores rendered in the wrong place and clobbered the menu frame.** This was the `draw_number` site above, and it was *live*, not latent — the [0.6.2] note below was wrong to call it dormant. Whenever `scores.dat` held a non-zero high score, the 64-byte write through the one-slot `digits` reservation corrupted `draw_number`'s own frame: the digits were drawn at the top-right corner instead of beside their menu row, and the menu's top-right corner bracket was overdrawn. It escaped every check because `screenshots/*.png` were captured with no `scores.dat` present, so every `draw_number` call took the `num == 0` early return and never touched the array. With the fix, the corner bracket is byte-identical to the committed art again and scores render beside their rows.
- **MCP Cone: the visible gap was never the passable gap** — `mcp_render` computed the ring's rotated segment into `effective_seg` and then tested the *raw* index, so the renderer ignored rotation entirely while `mcp_update`'s hit test honored it. Consequences: no ring ever appeared to turn, at any speed, for the whole game; and a shot fired dead-centre at the hole the player could see passed only on the phases where the two happened to coincide. Compounding it, the rotation was added to a segment index without conversion — `mcp_ring_angle` is in 1/160-turn units (the file's "degrees * 10" comment was wrong), not segments. Both sites now go through one shared `_mcp_seg_at(seg, ring_offset)`, so render and hit test agree by construction rather than by two copies of a formula staying in sync. `MCP_ANGLE_WRAP` / `MCP_ANGLE_PER_SEG` replace the bare `160`.
- **Disc Arena: the AI walked into every throw** — the block under `# Dodge incoming player disc` was a verbatim copy of the "track own disc for catch" block below it, signs and all, so the AI paddle moved *toward* the incoming disc. The AI now steps away, and the ±3 dead band (where neither test fires and a straight throw would arrive dead-centre against a stationary paddle) breaks the tie toward whichever edge has more room. **Difficulty needs play-testing** — this changes Disc Arena from unloseable to genuinely defended, and the right dodge speed is a feel question the headless suite cannot answer.
- **"NEW BEST" could never appear** — all four game-over screens compared `game_score` against `scores_get()`, but `scores_update()` had already stored the new high score by then, so the test was always false. A `game_new_best` flag is now set where the comparison actually happens and cleared when a run starts.
- **Out-of-bounds write in `engine_blit` on a panel smaller than the surface** — `_fb_scale` is floored to 1, so on a display narrower or shorter than 320×240 (fbtft SPI panels, vesafb 320×200) the scaled extent ran past the `_fb_blit` allocation. `engine_present` clamped its *device write* but not the blit, which made the overrun silent. `engine_probe_fb` now derives `_fb_src_w`/`_fb_src_h` — how much of the surface actually fits — and `engine_blit` walks those. Covered by the new `tests/engine-blit.tcyr`, which is mutation-checked: restoring the unclamped extent turns its guard assertion red.
- **`engine_blit` mis-packed every depth that was not 16 or 32bpp** — anything else fell into the 32bpp branch, which does a 4-byte `store32` while advancing by `_fb_bpp / 8`: at 8/15bpp that writes four times past each row, at 24bpp it overlaps every pixel and runs one byte past the last row. `engine_probe_fb` now refuses a depth the blitter does not implement and falls back instead of corrupting memory.
- **Unchecked ioctl and allocation results in the framebuffer probe** — a failed `FBIOGET_*` left the zeroed scratch in place, which the "driver reports nothing useful" guards silently turned into invented 320×240/32bpp geometry. Both ioctls are now checked, absurd geometry is rejected before `_fb_pitch * _fb_yres` can overflow to a negative size, and the `_fb_blit` and `_fb_ptr` allocations are guarded — `alloc()` returns 0 when the heap cannot grow (e.g. under `ulimit -v`), and the next statement used to `memset` through it.

### Changed — performance
- **`draw_clear` is word-wise: 443 µs → 49 µs per call (9.0×, measured).** The vendored stdlib `memset` is a byte-at-a-time loop, so clearing the 307,200-byte surface cost ~8.3M instructions on *every* frame of *every* game — this is the hottest call in the engine, with 10 per-frame call sites. The surface is `alloc()`-aligned and an exact multiple of 8, so 64-bit stores are equivalent.
- **`engine_blit` no longer replicates scaled rows through the byte-at-a-time stdlib `memcpy`.** That call sat inside the per-row loop; on a 2560×1440 panel (scale 6) it measured **15.1 ms per frame on its own** — the entire 16.67 ms budget — so the display path could not hold 60fps on an ordinary monitor. Now a word copy with a byte tail (the tail matters: the new extent clamp means `row_bytes` is no longer always a multiple of 8). Loop-invariant globals are hoisted out of the 76,800-iteration pixel loop, and the per-pixel `_fb_bpp == 16` re-test is now a hoisted flag.
- **`glow_apply` fast-rejects black pixels.** These frames are neon-on-black — 86–94% of pixels across the 14 reference screens are exactly 0 and can never clear the threshold. One 32-bit load and one compare now retires that case instead of three byte loads plus a three-way max, on each of ~75,684 interior pixels. Output is pixel-identical.
- **The `/dev/fb0`-absent fallback no longer rewrites a 230 KB PPM every frame.** `/dev/fb0` is `root:video` 0660, so for any user outside that group — and in CI — this was the *default* path: 230 KB of BGRA→RGB conversion plus a 230 KB write, 60 times a second, ~13.8 MB/s for a file nothing was reading at that rate. Throttled to roughly once a second.

### Security
- **`O_NOFOLLOW` on every file the game creates** (`src/engine.cyr` PPM writer, `scores.dat` in `src/main.cyr`), and mode tightened 0644 → 0600. The 14 `--ppm` outputs are fixed, predictable paths in a world-writable `/tmp`, and `scores.dat` is a *relative* path that lands in whatever directory the game was launched from. Verified end to end: with a same-owner symlink — the case `fs.protected_symlinks` deliberately does not cover — the old flags follow it and truncate the target, the new flags fail with `ELOOP` and the target is untouched. `O_EXCL` is deliberately not used; the fallback legitimately rewrites its own path.

### Added
- `tests/engine-blit.tcyr` — 5 assertions over the framebuffer blit against a synthetic undersized panel with guard bytes on both sides. CI cannot reach this path (no `/dev/fb0`), which is how the overrun above shipped.
- `tests/mcpcone-rotation.tcyr` — 9 assertions pinning render/hit agreement across all 160 rotation phases × 16 gap positions, that exactly one segment is open per phase, and that rotation is observable at all. Mutation-checked against the 0.6.2 behaviour.
- CI now runs `cyrius tests` (auto-discovery, 27 assertions across 3 suites) and fails if fewer suites run than there are `.tcyr` files — so a new suite that is never discovered cannot pass silently.

### Notes
- **`input.cyr`'s `var buf[4]` is deliberately left as a local.** It is the one function-local array that is safe under the one-slot reservation: every read is a 1-byte `SYS_READ` into `&buf` and every load is `load8(&buf)` at offset 0, so nothing past the reserved slot is ever touched. A comment now records why, so the next sweep does not have to re-derive it.
- **Static data 253,016 → 253,160 bytes** (+144) and binary 393,752 → 393,896. The growth is exactly the five relocated arrays: 8×8 + 4×8 + 3×(2×8). No new game code.
- Verified on the pinned toolchain: clean `cyrius deps` + build, `cyrius test tests/encom-hits.tcyr` 13 passed / 0 failed, and `--ppm` rendering all 14 screens at 320×240 (splash 230,415 bytes).
- **Rendering is unchanged where it was already correct.** With `scores.dat` moved aside — the condition the committed screenshots were captured under — all 14 rendered frames are `magick compare -metric AE` = 0 against `screenshots/*.png`, and byte-identical to the pre-change build. The only frames that differ from the pre-change build are the five that draw a non-zero number (`menu` and the four title cards whose game has a high score), and there the new output is the correct one.
- **The maze generator is behaviourally identical.** `maze_generate` was checksummed over its full wall array across 200 seeds and every supported width/height pairing, pre-change versus post-change: identical throughout. That site, and the three `engine.cyr` timespecs, were genuinely latent — the smashed slots happened to be dead.
- **Render verification for the rest of this release.** With `scores.dat` moved aside — the condition the committed screenshots were captured under — all 14 frames are `magick compare -metric AE` = 0 against `screenshots/*.png` except MCP Cone, whose 210 changed pixels are the rotation fix above. The word-wise `draw_clear`, the `engine_blit` rewrite and the `glow_apply` fast reject are all pixel-neutral. With `scores.dat` present, `menu` and the title cards differ from the committed art only by the score digits themselves (15 px and ~8 px), now drawn in the right place.
- `screenshots/mcpcone.png` regenerated — the committed frame showed the unrotated rings and no longer matched the game. All 14 reference frames match the build again.
- Binary 393,752 → 393,960 bytes; static data 253,016 → 253,224.
- **Not fixed here, and deferred to 0.7.x:** Battle Tanks player movement is not tick-gated (holding a direction outruns the AI and the player's own projectiles); the Tanks AI paths onto the player's own cell and stops; Interceptors freezes bullets in flight for ~1.5 s between waves; Light Cycles decides head-on collisions by update order, always killing Player 2; MCP Cone has no lose condition; and `gb_score` is a dead second scoring path. These are game-feel and balance changes that want play-testing alongside them, not a hardening pass.

## [0.6.2] — 2026-08-31

Toolchain and dependency refresh onto Cyrius 6.5.36. No game-logic changes —
every edit is a manifest pin, a vendored-stdlib refresh, or a documentation
correction.

### Changed
- **Toolchain pin 6.0.52 → 6.5.36** — `cyrius.cyml` `[package].cyrius`. The pin is what `cyrius deps` uses to select the stdlib snapshot under `~/.cyrius/versions/<pin>/lib`, so until now the project was compiling a 6.0.52 stdlib with a 6.5.36 `cycc` and every build printed `warning: cyrius.cyml pins 6.0.52 but cycc is 6.5.36 — toolchain drift`. That warning is gone. Both CI workflows derive `CYRIUS_VERSION` from this field by grep, so no YAML edit was needed for the install step.
- **Vendored stdlib refreshed** — the transitive closure of the unchanged `[deps].stdlib = ["string", "alloc", "vec", "assert"]` grew from 9 files to 17. `assert` now includes `lib/syscalls.cyr` and `alloc` includes `lib/atomic.cyr`, which pull in `atomic` plus the six per-arch/per-OS `syscalls_*` peers. `lib/` is git-ignored and regenerated by `cyrius deps`, so this is a build-input change only.
- **Manifest dependency notes corrected** — the `[deps]` comment claimed "no `syscalls` module is needed"; that is no longer true of what gets vendored, even though encom still declares its own `SYS_*` enum and calls the `syscall` builtin directly. The incoming stdlib `SYS_*` / `O_*` constants duplicate names `src/engine.cyr` declares, but every colliding value is identical and duplicate enum constants are a warn-only guardrail, so the build stays clean.
- **Dormant `[deps.vani]` pin 0.9.4 → 1.2.2** — and the adjacent note "cyrius-doom pins 0.9.4" removed: it was false. cyrius-doom has no `[deps.vani]` block at all; it, cyrius-polyomino and cyrius-bb each commit vani's single-file `core` profile under `vendor/` instead, because resolving vani as a git dep drags its whole manifest tree into the link and DCE cannot prune a vendored module. The block stays commented and unresolved until the MCP Voice phase.
- **CI comment accuracy** — the Test step's note that bare `cyrius test` is "singular (fuller tests/ auto-discovery lands later in the 6.0.x line)" is stale: on 6.5.36 both bare `cyrius test` and `cyrius tests` recursively auto-discover every `.tcyr` under `tests/`. The explicit path is retained deliberately, so this is a comment fix only. The Lint step's "matches cyrius-doom" citation was likewise dropped, and the warning count corrected to the eight `src/main.cyr` tank-input one-liners that actually exceed 120 chars.
- **Security-scan units** — the "no oversized stack buffers" gate documented `var name[N]` as N BYTES and flagged `N >= 65536`. On the pinned toolchain a file-scope `var name[N]` reserves N *slots* (N×8 bytes), so the 64KB bound is `N >= 8192`. Threshold and wording corrected; encom's largest arrays (`_ai_*[4800]`, `lc_grid[4800]` = 38,400 bytes each, all `.bss` statics) remain well under it.

### Fixed
- **Documentation drift** — `README.md` required "Cyrius >= 6.0.52" (now 6.5.36) and still carried pre-0.6.1 line counts (3,872 across 14 files; actually 4,016, with `engine.cyr` 160 → 300 after the framebuffer geometry probe and `draw.cyr` 138 → 141). `CLAUDE.md` still declared the version as 0.6.0. `docs/development/roadmap.md` still had a v0.6.0 status line and marked v0.6.0 "(current)"; it now records v0.6.1 and v0.6.2.

### Notes
- **The 6.0.x constant-fold workaround is no longer required, and is retained anyway.** The chained `enum * enum * literal` mis-fold that forced `SCREEN_W * (SCREEN_H * 4)` in `src/engine.cyr` (×3) and `src/draw.cyr` (×1) was fixed upstream in Cyrius 6.1.37 — same root cause, same `320*200*4` shape, filed by cyrius-doom. Verified on 6.5.36: both the chained and right-nested groupings fold to 307200. The four sites are unchanged; only their `NOTE:` comments were updated so they no longer imply the current toolchain needs the grouping.
- **Binary size 367,856 → 393,752 bytes** (+25,896, ~7%). This is the larger 6.5.36 stdlib riding along as dead code — unreachable-function count went 87 → 207 — not new game code. Static data grew 251,208 → 253,016 bytes.
- Verified on the pinned toolchain: clean build, `cyrius test tests/encom-hits.tcyr` 13 passed / 0 failed, and `--ppm` rendering all 14 screens at 320×240 (splash 230,415 bytes).
- **Known issue, pre-existing and not introduced here — since fixed, see [Unreleased].** A *function-local* `var X[N]` reserves a single 8-byte stack slot on this toolchain regardless of `N`, while file-scope arrays correctly reserve N slots. Five sites index past that one slot via `store64(&X + i*8, …)`: `digits[8]` in `main.cyr` `draw_number`, `cand_dir[4]` in `grid.cyr`, and the `ts[2]`/`ts[2]`/`sleep_ts[2]` timespecs in `engine.cyr`. An isolated reproducer using the same idiom segfaults.

  The assessment recorded here — "encom's own frames survive it and render correctly, so this is latent rather than live" — was wrong for the `draw_number` site, and the reason it looked correct is worth keeping. `screenshots/*.png` were all captured with no `scores.dat` in the working directory, so every `draw_number` call hit the `num == 0` early return and the 8-slot array was never written. Restore a `scores.dat` with a non-zero high score and the menu and title cards visibly corrupt. The `grid.cyr` and `engine.cyr` sites were latent as described. Fixed in [Unreleased] by moving all five to file-scope `.bss` like `_ai_*`.

## [0.6.1] — 2026-06-03

Framebuffer display fix — the games now render correctly on a real Linux
console instead of tiling into the top band of the panel. Same root cause and
fix as the sister projects (cyrius-doom `c9320b5`, cyrius-polyomino `83bd91a`).

### Fixed
- **Framebuffer geometry probing** — `engine_present` blitted the packed 320×240 BGRX surface straight to `/dev/fb0` with `lseek(0)` + one contiguous `write`, assuming the panel was exactly 320×240 with a 1280-byte pitch. On any real console the physical scanline pitch (`line_length`) and resolution differ, so the surface tiled horizontally and collapsed into the top ~20px of the display (image repeated ~8× across). `engine_init` now probes the real geometry via `FBIOGET_VSCREENINFO` / `FBIOGET_FSCREENINFO` (ioctl), and the new `engine_blit` integer-scales + centers the surface into a full-screen scratch buffer, honoring the panel's pitch and bit depth (32bpp BGRX verbatim copy, 16bpp RGB565 pack), writing only the active band each frame with the letterbox bars blacked once at init. Degrades gracefully when `/dev/fb0` is unavailable (PPM fallback unchanged).

### Notes
- Render/simulation logic is unchanged — the only edits are in `src/engine.cyr` (display path). The `--ppm` screenshot path is untouched and still emits all 14 frames at 320×240.

## [0.6.0] — 2026-06-03

Toolchain modernization + first tagged pre-release. Brought the project onto the
Cyrius 6.0.52 build system, matching the sister projects (cyrius-doom,
cyrius-polyomino, cyrius-bb).

Re-baselined the version line below 1.0 — nothing had been tagged yet, so
`0.6.x → 0.9.x` is now reserved for play-testing, bug-fixing, and a full
security audit before the `1.0.0` release.

### Changed
- **Build manifest** — replaced the legacy `cyrius.toml` (`[project]`/`[deps]`/`[build]`/`[toolchain]`) with a `cyrius.cyml` manifest (`[package]`/`[build]`/`[deps]`) pinned to `cyrius = "6.0.52"`, version sourced from `VERSION` via `${file:VERSION}`. `lib/` is now resolved by `cyrius deps` and git-ignored as a build artifact.
- **Dependency surface** — stdlib deps are now `string`, `alloc`, `vec`, `assert`. `fmt` was dropped as a direct dep (the games hand-render every glyph via the 3×5 bitmap font); it still rides in transitively via `assert`, and `vec` is listed so `fmt`'s variadic `vec_get` path stays resolved and the build is warning-free.
- **Toolchain pin** — removed the stale `.cyrius-toolchain` (4.8.5-1) file; the `cyrius` field in `cyrius.cyml` is now the single source of truth. README/CONTRIBUTING bumped to require Cyrius ≥ 6.0.52.
- **Test suite** — rewrote `tests/encom-hits.tcyr` for the 6.x toolchain: `#` comments (the lexer no longer accepts `//`), `include "src/types.cyr"` so the constant assertions resolve, and the stdlib `assert_*` framework with `assert_summary()`. 13 assertions, all passing.

### Added
- `src/test.cyr` — top-level `[build].test` entry, and `cyrius deps`-based vendoring of `lib/`, mirroring the sibling project layout.
- **CI + release workflows** — `.github/workflows/ci.yml` (build · lint · `cyrius test tests/encom-hits.tcyr` · headless `--ppm` smoke · docs/version/security gates) and `release.yml` (tag-triggered, bare-SemVer tags, version-matched GitHub release), mirroring cyrius-polyomino.

### Fixed
- **Framebuffer sizing under Cyrius 6.0.x** — the toolchain mis-folds a chained `enum * enum * literal` constant expression, dropping the first factor (`SCREEN_W * SCREEN_H * 4` evaluated to `SCREEN_H * 4` = 960 instead of 307200). This silently under-allocated the framebuffer and PPM buffers and crashed `--ppm`/gameplay rendering in a null `memset`. Reworked the four affected sites (`engine.cyr` ×3, `draw.cyr` ×1) to right-nest the grouping — `SCREEN_W * (SCREEN_H * 4)` — which folds correctly. `--ppm` again renders all 14 screenshots (320×240, correct byte sizes).

### Notes
- Game logic is unchanged from 0.5.0 — the only source edits are the four constant-grouping fixes above, required for correctness on the 6.0.x compiler.

## [0.5.0] — 2026-04-15

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
