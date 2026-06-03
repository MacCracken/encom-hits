# Security Policy

**Email**: security@agnos.io

## Attack Surface

- **Keyboard input** — terminal raw mode, non-blocking stdin reads. ISIG disabled; Ctrl+C mapped to graceful quit via ETX byte detection.
- **Score file** — `scores.dat`, 48-byte binary (6 x i64). Loaded at startup, validated: values clamped to [0, 99999999]. Written with 0644 permissions.
- **No network** — single-player/local only. No sockets, no DNS, no HTTP.
- **No asset loading** — all visuals computed at runtime. No file format parsing except scores.dat.

## Audit (v0.5.0 — initial pass)

Seven issues found and fixed in the first audit pass. A deeper security audit
is scheduled as part of pre-1.0.0 hardening (see `docs/development/roadmap.md`,
v0.7→v0.9) — re-reviewing input parsing, save-file I/O, and bounds before the
1.0.0 release.

| Severity | Issue | Fix |
|----------|-------|-----|
| Critical | Bug spawn Y coordinate out-of-bounds | Modulo clamp on spawn coords |
| Critical | draw_number 8-slot buffer overflow on large values | Cap extraction at 8 digits |
| Critical | PPM fallback path leaked 230KB per frame | Pre-allocate in engine_init |
| High | Ctrl+C silently eaten (ISIG disabled) | Map ETX to KEY_Q |
| High | Score file values read without validation | Clamp to [0, 99999999] |
| Medium | scores.dat created with 0666 permissions | Changed to 0644 |
| Medium | Xorshift PRNG could reach zero fixed-point | Guard seed=0 → seed=1 |

## Accepted Risks

- Terminal not restored on SIGKILL — no signal handler. User runs `reset` if needed.
- Relative path `scores.dat` writes to CWD — acceptable for a game binary.
- Packed coordinate encoding (x * 1000 + y) produces wrong values for negative y, but bounds checking prevents unsafe access.

**Last Updated**: 2026-06-03
