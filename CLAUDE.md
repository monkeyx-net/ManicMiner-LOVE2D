# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

A LÖVE2D (Love2D) port of the 1983 ZX Spectrum game Manic Miner, written in Lua. The target runtime is LÖVE 11.5 / LuaJIT. All game logic runs at a fixed 60 Hz tick rate with a 30 Hz render target.

## Running and Packaging

```bash
# Run the game (requires love 11.5 installed)
love src/

# Package into a .love archive (used by CI for all platform builds)
cd src && zip -9 -r ../ManicMiner.love .
```

There is no test suite or linter. Development is run-and-observe.

## Releasing

The CI workflow (`build.yml`) reads the version from the **first** `## [x.y.z]` header in `CHANGELOG.md`. On push to `main`, if that version tag does not yet exist as a GitHub Release, it builds all platforms and publishes one. To cut a release: add a new `## [x.y.z] - YYYY-MM-DD` section at the top of `CHANGELOG.md` and push to `main`.

## Code Architecture

### Module system (flat globals, no return values)

All `src/*.lua` files write directly into the global namespace — there is no `return` / `require`-result pattern. `require("foo")` is used purely for side effects. Modules may call functions from other modules freely, so load order matters:

- `common.lua`, `misc.lua`, `replay.lua` — loaded at parse time (before `love.load`), no Love2D graphics API
- Everything else — required inside `love.load()` after the graphics context exists

### State machine (`common.lua`)

The entire game is driven by four global function pointers updated by `SetState()`:

| Pointer | Called when | Purpose |
|---|---|---|
| `Action` | Every tick | One-shot initialisation or transition (sets itself to `DoNothing` when done) |
| `Ticker` | Every tick | Ongoing game logic (movement, AI, physics) |
| `Drawer` | Every tick | Pixel rendering into the video buffer |
| `Responder` | On key/button event | Handle discrete input events |

`DoNothing` is the sentinel no-op. Each screen (title, game, die, gameover, victory, trans, loader) owns its own set of these four functions and calls `SetState()` to take control.

### Rendering pipeline (`video.lua`)

Rendering is entirely software (no Love2D sprites or canvases for game content):

1. **`videoPixel[]`** — flat array of 49152 integers (256×192), stores collision flags:
   - `B_LEVEL = 1` — level tile ink pixel
   - `B_ROBOT = 2` — robot sprite pixel
   - `B_MINER = 4` — SPG tile flag = 8
2. **`imgData`** — Love2D `ImageData` holding actual RGB values, written by `setPixel`
3. **`imageDirty`** flag — set whenever `imgData` changes; `Video_Flush()` calls `screenImage:replacePixels(imgData)` once per render frame (not per tick)
4. Sprites are blended in per-tick by `Video_SpriteBlend` / `Video_Miner`, then cleaned by `Video_ClearSprites()` which uses `spriteDirtyList[]` to only touch pixels that changed

Pixel positions are always flat indices: `pos = y * WIDTH + x`. `TILE2PIXEL(tileIndex)` converts a 0-511 tile index to a pixel offset.

Performance-critical functions localize globals as upvalues (`local band, rshift = band, rshift`) to avoid metatable lookups in LuaJIT's inner loops.

### Game loop (`main.lua`)

```
love.update(dt):
  Audio_Update(dt)           -- every frame, fills audio queue
  tick accumulator loop:     -- fixed 60 Hz, capped at 4 ticks debt
    Action()
    Ticker()
    Drawer()
  Video_Flush()              -- upload imgData → GPU once per frame
  sleep to cap at TARGET_FPS
```

`love.draw()` only draws the cached `screenImage` texture scaled to the window with letterboxing.

### Level data (`levels.lua`)

`levelData` is a 0-indexed global table (indices 0–19). Each entry:
- `.name` — string
- `.data` — 512-element flat array (32 columns × 16 rows), each value is a tile index into `.gfx`/`.info`
- `.gfx` — 8 entries, each an array of 8 bytes (one byte per pixel row of an 8×8 tile)
- `.info` — 8 entries, each `{colour=0xXY, type=T_*}` where colour is a ZX Spectrum attribute (high nibble = paper, low nibble = ink)

Special level indices: `EUGENE=4`, `SKYLAB=13`, `SPG=18`, `TWENTY=19`.

### Audio (`audio.lua`)

Pure software square-wave synthesis into a Love2D `QueueableSource` at 22050 Hz, 16-bit stereo. 8 channels total: channels 1–3 are SFX, channels 4–8 are music. The music score data is embedded as flat byte arrays in the file and decoded by `Audio_MusicEvent()` using a simple event protocol (`EV_NOTEON`, `EV_NOTEOFF`, `EV_DRAW`, etc.).

### Persistence (`love.filesystem`)

All files are written to the OS-sandboxed app data directory (Love2D `identity = "ManicMiner"`):

| File | Contents |
|---|---|
| `levelscores.dat` | Per-level high scores |
| `gameconfig.dat` | Starting lives / level config |
| `savestate_1.dat` – `savestate_5.dat` | Full game state snapshots |
| `replay.dat` | Input recording (LEFT/RIGHT/JUMP per miner tick) |

### Input replay (`replay.lua`)

`replayMode` (`REPLAY_NONE=0`, `REPLAY_RECORDING=1`, `REPLAY_PLAYING=2`) is a global read by `System_IsKey()` in `common.lua`. During recording, each `DoMinerTicker` call appends a 3-bit byte (LEFT|RIGHT|JUMP) to `buffer[]`. During playback, `System_IsKey` reads from that buffer instead of querying hardware, making replay deterministic.

### Timer (`misc.lua`)

`Timer_New(numerator, divisor)` creates a fractional-rate timer. `Timer_Update(timer)` returns the number of logical frames to advance this tick (either `floor(n/d)` or `floor(n/d)+1`), distributing the remainder evenly. Used to run subsystems at rates like 7/60 Hz.

## Key Conventions

- **0-indexed data, 1-indexed Lua tables**: level/palette/tile indices are 0-based in game logic, but all Lua arrays are 1-based, so palette colour `n` is `palette[n+1]`.
- **Bit operations**: `band`, `bor`, `bxor`, `lshift`, `rshift` are globals injected from LuaJIT's `bit` library in `common.lua`. Hot-path code re-localizes them as upvalues.
- **No returns from modules**: never add `return` to module files.
- **`gameDemo`**: when `gameDemo == 1`, the game runs in attract/demo mode (auto-returns to title after 64 ticks, miner has no ticker/drawer). Set to `0` for real play.
- **Conveyor direction encoding**: level `.info` types `T_CONVEYL=7` / `T_CONVEYR=8` drive the `conveyor` global direction. The conveyor graphic in `.gfx` is stored as a wall mask whose bitwise inverse gives the animated frame.

## Tools (`tools/`)

- `tap_to_lua.py` — converts a ZX Spectrum `.TAP` file (e.g. `MANIC.TAP`) to a `levels.lua`-compatible Lua file. Run as `python3 tools/tap_to_lua.py MANIC.TAP [output.lua]`.
- `convert_levels.py` — alternate level converter.
