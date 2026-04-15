# Contributing to ENCOM's Hits

See [AGNOS First-Party Standards](https://github.com/MacCracken/agnosticos/blob/main/docs/development/applications/first-party-standards.md).

## Key Rules

- Every visual is a line or shape — no sprites, no textures, no assets
- Each game should be 200-300 lines. Over 800 means overscoped.
- Play test every change — feel matters
- Frame time target: <4ms per frame at 320x240

## Adding a New Game

1. Create `src/yourgame.cyr` with `init`, `update`, `render`, `game_over` functions
2. Add game ID to `types.cyr` enum
3. Add include to `main.cyr` (order matters — single-pass compiler)
4. Add menu entry, title card, input handler, game tick function in `main.cyr`
5. Add score tracking and `--ppm` screenshot entry
6. Run `./build/encom-hits --ppm` to verify screenshots

## Build

```sh
cyrius build src/main.cyr build/encom-hits
```

## License

GPL-3.0-only
