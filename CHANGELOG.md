# Changelog

All notable changes to Manic Miner LÖVE2D are documented here.

## [0.9.4] - 2026-04-23

### New Features
 - Press R to record a game sesson. R to stop
 - Game savestate now supports 5 slots. 
 - U Key to save and pick slot
 - Save stated managed in Options Menu O Key on startup.

## [0.9.3] - 2026-03-25

### Minor update
 - Added original zlib license
 - video and audio performance tweaks


## [0.9.2] - 2026-03-18

### Fixed

- Keys now blink in sequence rather in parallel
- Solar Beams now deflect correctly
- Victory sprite now shows(Colours still need to be fixed)

### New

- U Key - Now saves current position and level
- O Key - access options screen
  - Set starting level
  - Set number of lives

## [0.9.1] - 2026-03-17

### Overview

Initial public release of the LÖVE2D port of the classic 1983 ZX Spectrum game
Manic Miner, originally written by Matthew Smith and previously ported to C/SDL2
by fawtytoo. This release brings the game to a broad range of modern platforms
via the LÖVE2D framework.

### Features

- Full 20-level recreation of the original ZX Spectrum Manic Miner
- Per-pixel colouring, eliminating the colour clashing of the original hardware
- Authentic 16-colour ZX Spectrum palette
- Two replacement character-set fonts (small and large)
- Corrected piano keyboard on the title screen
- Redrawn title screen for a more balanced visual layout
- Polyphonic in-game and title music reproduced from the original score
- Stereo-panned sound effects using a square-wave generator for a retro beepy feel
- Per-level high scores — saved locally and displayed on the title screen
- Level names shown alongside scores
- Cheat mode activated with the original ZX Spectrum key sequence
  - Keys 1–0 select levels 1–10; Shift + 1–0 selects levels 11–20
- Gamepad / controller support (D-pad, left analogue stick, face buttons)

### Platform Support

| Platform        | Format                        |
|-----------------|-------------------------------|
| Linux x86_64    | AppImage (self-contained)     |
| Linux aarch64   | AppImage (self-contained)     |
| Windows x86_64  | Zip (exe + DLLs)              |
| macOS           | Zip (.app bundle)             |
| Android         | APK (debug, sideload-ready)   |
| Any (LÖVE2D)    | `.love` archive               |

### Controls

| Action          | Keyboard     | Controller               |
|-----------------|--------------|--------------------------|
| Move left/right | Cursor keys  | D-pad / left analogue    |
| Jump            | Space        | A button                 |
| Pause           | Tab          | X button                 |
| Music on/off    | Alt          | Y button                 |
| High scores     | S            | B button (title screen)  |

### CI / Build

- GitHub Actions workflow builds all platform targets automatically on every
  push to `main` and on every `v*` tag push.
- Tagged releases publish a GitHub Release containing all platform artifacts.
