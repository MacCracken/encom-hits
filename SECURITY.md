# Security Policy

**Email**: security@agnos.io

## Attack Surface

- **Keyboard input** — terminal raw mode, at most one 64-byte non-blocking read per frame, decoded by a byte-at-a-time escape-sequence parser (`src/input.cyr`). It consumes CSI and SS3 sequences whole and drops unfinished ones after two frames, so no byte of an unknown sequence reaches the game's key map. ISIG is disabled; Ctrl+C arrives as byte 3 and quits through the normal path.
- **Terminal state** — the original termios is restored on Q/Ctrl+C, and by handlers for SIGHUP, SIGINT, SIGQUIT, SIGTERM, SIGILL, SIGABRT, SIGBUS, SIGFPE and SIGSEGV, which then re-raise the signal. When stdin is not a terminal the game refuses to start, rather than block on a read.
- **Score file** — `scores.dat` in the current directory, 48 bytes (6 x i64). It is opened with `O_NOFOLLOW` for both read and write, and created mode 0600. A short read leaves zeros, and every value is clamped to [0, 99999999] on load.
- **Screenshot and fallback frames** — fixed paths in `/tmp` (`encom_*.ppm`, `encom-hits.ppm`), opened `O_NOFOLLOW` so a planted symlink cannot redirect the write.
- **Command line** — read from `/proc/self/cmdline` into a 512-byte buffer; only an exact `--ppm` argument is recognised.
- **Framebuffer geometry** — taken from the driver's `FBIOGET_*SCREENINFO`. Failed ioctls, depths other than 16/32 bpp, and resolutions or pitches too large to be real are refused before any buffer is sized from them. Panels smaller than 320x240 are clamped (covered by `tests/engine-blit.tcyr`).
- **No network** — single-player, local only. No sockets, no DNS, no HTTP.
- **No asset loading** — all visuals are computed at runtime. No file format parsing except `scores.dat`.

## Audits

### v0.8.3 — P(-1) sweep

| Severity | Issue | Fix |
|----------|-------|-----|
| Medium | Terminal left raw after an external signal or a crash | Signal handlers restore termios, then re-raise |
| Medium | Stdin that is an open pipe blocked the first read forever | Refuse to start without a terminal |
| Low | Input read until the tty ran dry, so a flood could stall a frame indefinitely | One bounded read per frame |
| Low | Unknown escape sequences leaked bytes into game keys (F5 launched a game) | Escape-sequence parser |
| Low | `--ppm` matched anywhere in the command line, argv[0] included | Exact argument match |
| Low | Allocation failure in `engine_init` led to writes through a null pointer | Checked; exit 1 with a message |

### v0.8.2 — cross-target check

| Severity | Issue | Fix |
|----------|-------|-----|
| High | On aarch64, the local `O_NOFOLLOW` was `O_LARGEFILE`, silently dropping the symlink refusal | Use the stdlib's per-target constants |

### v0.6.3 — P-1 audit

Out-of-bounds blit write on panels smaller than 320x240; unsupported framebuffer depths corrupting memory; unchecked ioctls and allocations; `O_NOFOLLOW` and mode 0600 for every file the game creates. See the CHANGELOG.

### v0.5.0 — initial pass

| Severity | Issue | Fix |
|----------|-------|-----|
| Critical | Bug spawn Y coordinate out-of-bounds | Modulo clamp on spawn coords |
| Critical | draw_number 8-slot buffer overflow on large values | Cap extraction at 8 digits |
| Critical | PPM fallback path leaked 230KB per frame | Pre-allocate in engine_init |
| High | Ctrl+C silently eaten (ISIG disabled) | Map ETX to KEY_Q |
| High | Score file values read without validation | Clamp to [0, 99999999] |
| Medium | scores.dat created with 0666 permissions | Changed to 0644 (0600 since v0.6.3) |
| Medium | Xorshift PRNG could reach zero fixed-point | Guard seed=0 → seed=1 |

## Accepted Risks

- **SIGKILL** cannot be caught, so the terminal stays raw after `kill -9`. Run `reset`.
- **`scores.dat` is relative to the current directory**, so high scores depend on where the game is launched. Revisited before 1.0.0 (roadmap v0.9.0).
- **The `/dev/fb0` present path is not exercised in CI** (there is no framebuffer there). Its blit is covered against synthetic panels by `tests/engine-blit.tcyr`; real-console runs are part of each play-test.

**Last Updated**: 2026-11-07
