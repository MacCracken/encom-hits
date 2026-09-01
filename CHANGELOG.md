# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

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
