# Contributing to ENCOM's Hits

See [AGNOS First-Party Standards](https://github.com/MacCracken/agnosticos/blob/main/docs/development/applications/first-party-standards.md).

## Key Rules

- Every visual is a line or shape — no sprites, no textures, no assets
- Each game should be 200-500 lines. Over 800 means overscoped.
- Play test every change — feel matters
- Frame time target: <4ms per frame at 320x240

## Adding a New Game

1. Create `src/yourgame.cyr` with `init`, `update`, `render`, `game_over` functions
2. Add game ID to `types.cyr` enum
3. Add include to `main.cyr` (order matters — single-pass compiler), and to the include list in `tests/play.tcyr`
4. Add a menu row and title card in `screens.cyr`
5. Add an input handler, a tick rate, a game tick (ending the run with `_play_finish`) and the `play_frame` dispatch in `play.cyr`
6. Add a `--ppm` screenshot entry in `main.cyr`'s `_screenshot_mode`
7. Regenerate the reference frames (`sh tests/frames.sh build/encom-hits --update`) and the PNGs in `screenshots/`, and add a row to `benches/frame.bcyr`

## Build

```sh
cyrius deps                                   # vendor stdlib into lib/ (first build only)
cyrius build src/main.cyr build/encom-hits
cyrius test tests                             # run every .tcyr suite under tests/
sh tests/frames.sh build/encom-hits           # check all 28 reference frames
cyrius bench benches/frame.bcyr               # frame times
```

Every change must keep the frames matching `tests/frames.sha256`. When a change is meant to alter what is drawn, regenerate it with `--update`, regenerate the affected PNG in `screenshots/`, and say which frames changed in the CHANGELOG.

## License

GPL-3.0-only
