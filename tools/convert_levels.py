#!/usr/bin/env python3
"""
convert_levels.py — Convert Levels/*.txt level definitions to Lua snippets
compatible with ManicMiner-LOVE2D's data format.

Usage:
    python3 tools/convert_levels.py [FILE ...] [--start-index N] [--out-dir DIR]

    FILE        One or more .txt level files (default: Levels/*.txt sorted)
    --start-index N   Starting Lua levelData index (default: 0)
    --out-dir DIR     Directory for output files (default: current directory)

Output files:
    out_levels.lua   — levelData[N] blocks for src/levels.lua
    out_miner.lua    — minerStart entries for src/miner.lua
    out_robots.lua   — robotStartData entries for src/robots.lua
    out_portal.lua   — portalData entries for src/portal.lua

Notes:
    • gfx arrays are stubs ({0,0,...}) — fill in real 8-byte Spectrum sprite data.
    • robot gfx field is 0 (placeholder) — map sprite IDs to robotSprite[] indices.
    • speed is taken as abs(txt_speed); direction sets move="left"/"right"/"up"/"down".
"""

import sys
import os
import glob
import argparse

# ---------------------------------------------------------------------------
# Color name → Lua colour value (ZX Spectrum ink index with bright bit)
# colour = (bright << 3) | ink_number
# ---------------------------------------------------------------------------
COLOR_MAP: dict[str, int] = {
    "black":     0x00, "blue":      0x01, "red":       0x02, "magenta":   0x03,
    "green":     0x04, "cyan":      0x05, "yellow":    0x06, "white":     0x07,
    "b.black":   0x08, "b.blue":    0x09, "b.red":     0x0a, "b.magenta": 0x0b,
    "b.green":   0x0c, "b.cyan":    0x0d, "b.yellow":  0x0e, "b.white":   0x0f,
}

# Tile type name → Lua T_ constant
TILE_TYPE_MAP: dict[str, str] = {
    "blank":   "T_SPACE",
    "floor":   "T_FLOOR",
    "crumble": "T_COLLAPSE",
    "wall":    "T_SOLID",
    "lconvey": "T_CONVEYL",
    "rconvey": "T_CONVEYR",
    "nasty":   "T_HARM",
    "item":    "T_ITEM",
    "switch":  "T_SWITCHOFF",
    "portal":  "T_ITEM",      # portal-as-tile (rare) treated as item
}

# nframes defaults by move type
NFRAMES: dict[str, int] = {
    "right":  7, "left":   7,
    "up":     3, "down":   3,
    "kong":   1,
    "skylab": 7,
}

# Starting frame: left-moving starts at last frame (7), others at 0
START_FRAME: dict[str, int] = {
    "left": 7, "up": 0, "right": 0, "down": 0, "kong": 0, "skylab": 0,
}


def color_hex(name: str) -> str:
    """Return Lua hex literal for a color name, e.g. '0x0a'."""
    v = COLOR_MAP.get(name.lower().strip(), 0x07)
    return f"0x{v:02x}"


def color_val(name: str) -> int:
    return COLOR_MAP.get(name.lower().strip(), 0x07)


# ---------------------------------------------------------------------------
# Parser
# ---------------------------------------------------------------------------

def parse_level(path: str) -> dict | None:
    """Parse a .txt level file into a structured dict."""
    with open(path, encoding="utf-8", errors="replace") as f:
        raw_lines = f.readlines()

    lines = [ln.rstrip("\n") for ln in raw_lines]

    if len(lines) < 18:
        print(f"  SKIP {path}: too few lines ({len(lines)})", file=sys.stderr)
        return None

    name    = lines[0].strip()
    # platform = lines[1]  (ignored)
    grid    = lines[2:18]   # 16 rows, each ≥32 chars (pad if needed)
    bg_color = lines[18].strip() if len(lines) > 18 else "black"

    # Pad grid rows to exactly 32 chars
    grid = [(row + " " * 32)[:32] for row in grid]

    # --- Parse tile definitions (lines after bg_color until blank line) ---
    tiles: list[dict] = []    # ordered list of {char, id, type, colors}
    entity_lines: list[str] = []
    in_entities = False
    in_tiles = True

    for line in lines[19:]:
        stripped = line.strip()
        if not stripped:
            if in_tiles:
                in_tiles = False
                in_entities = True
            continue

        if in_entities:
            entity_lines.append(stripped)
            continue

        # Tile definition line: CHAR(s) ID TYPE COLOR [COLOR2]
        # blank tile starts with spaces: "  0000 blank black"
        # normal tile: "- 0001 floor b.red"
        parts = line.split()
        if len(parts) < 2:
            continue

        # Blank tile: line starts with spaces → "  0000 blank black"
        # Normal tile: line starts with char  → "- 0001 floor b.red"
        if line[0] == ' ':
            char = ' '
            # parts = [id, type, color, ...]
            if len(parts) < 3:
                continue
            tile_id   = parts[0]
            tile_type = parts[1]
            color1    = parts[2] if len(parts) > 2 else "black"
            color2    = parts[3] if len(parts) > 3 else ""
        else:
            char = line[0]
            # parts = [char, id, type, color, ...]
            if len(parts) < 4:
                continue
            tile_id   = parts[1]
            tile_type = parts[2]
            color1    = parts[3] if len(parts) > 3 else "black"
            color2    = parts[4] if len(parts) > 4 else ""

        tiles.append({
            "char":   char,
            "id":     tile_id,
            "type":   tile_type.lower(),
            "color":  color1,
            "color2": color2,
        })

    return {
        "name":     name,
        "grid":     grid,
        "bg_color": bg_color,
        "tiles":    tiles,
        "entities": entity_lines,
        "source":   os.path.basename(path),
    }


def parse_entities(entity_lines: list[str]) -> dict:
    """Split entity lines into willy, robots, portal."""
    willy  = None
    robots = []
    portal = None

    for line in entity_lines:
        parts = line.split()
        if len(parts) < 2:
            continue
        sprite_id = parts[0]
        etype     = parts[1].lower()

        if etype == "willy":
            # 0000 willy X Y FRAME DIR COLOR
            try:
                x, y = int(parts[2]), int(parts[3])
                frame = int(parts[4]) if len(parts) > 4 else 0
                dirv  = int(parts[5]) if len(parts) > 5 else 0
                color = parts[6] if len(parts) > 6 else "white"
                willy = {"x": x, "y": y, "frame": frame, "dir": dirv, "color": color,
                         "sprite_id": sprite_id}
            except (ValueError, IndexError):
                pass

        elif etype in ("hguard", "vguard", "kong", "skylab"):
            # hguard: ID hguard X Y MIN MAX SPEED COLOR
            # vguard: ID vguard X Y MIN MAX SPEED COLOR
            # kong:   ID kong   X Y MIN MAX SPEED COLOR
            # skylab: ID skylab X Y MIN MAX SPEED COLOR
            try:
                x, y = int(parts[2]), int(parts[3])
                minv  = int(parts[4])
                maxv  = int(parts[5])
                speed = int(parts[6])
                color = parts[7] if len(parts) > 7 else "white"

                if etype == "hguard":
                    move = "left" if speed < 0 else "right"
                elif etype == "vguard":
                    move = "up"   if speed < 0 else "down"
                elif etype == "kong":
                    move = "kong"
                elif etype == "skylab":
                    move = "skylab"
                else:
                    move = "right"

                robots.append({
                    "sprite_id": sprite_id,
                    "etype":     etype,
                    "x": x, "y": y,
                    "min": minv, "max": maxv,
                    "speed": abs(speed),
                    "move":  move,
                    "color": color,
                })
            except (ValueError, IndexError):
                pass

        elif etype == "dguard":
            # dguard has a different parameter layout — emit as comment only
            robots.append({"etype": "dguard", "raw": line})

        elif etype == "portal":
            # ID portal X Y INK PAPER
            try:
                x, y   = int(parts[2]), int(parts[3])
                ink    = parts[4] if len(parts) > 4 else "white"
                paper  = parts[5] if len(parts) > 5 else "blue"
                portal = {"sprite_id": sprite_id, "x": x, "y": y,
                          "ink": ink, "paper": paper}
            except (ValueError, IndexError):
                pass

    return {"willy": willy, "robots": robots, "portal": portal}


# ---------------------------------------------------------------------------
# Lua emitters
# ---------------------------------------------------------------------------

def emit_level(idx: int, lv: dict) -> list[str]:
    """Emit levelData[idx] = { ... } block."""
    tiles    = lv["tiles"]
    grid     = lv["grid"]
    bg_color = lv["bg_color"]
    name_esc = lv["name"].replace("\\", "\\\\").replace('"', '\\"')

    # Build char→tile_index mapping (blank=index 0, others in order)
    char_map: dict[str, int] = {}
    for i, t in enumerate(tiles):
        ch = t["char"]
        if ch not in char_map:
            char_map[ch] = i

    lines = [f'-- Level {idx}: {lv["name"]} (from {lv["source"]})']
    lines.append(f'levelData[{idx}] = {{')
    lines.append(f'    name = "{name_esc}",')

    # data: 16×32 = 512 tile indices
    lines.append("    data = {")
    for r, row in enumerate(grid):
        comma = "," if r < 15 else ""
        indices = [str(char_map.get(ch, 0)) for ch in row]
        lines.append(f'        {",".join(indices)}{comma}')
    lines.append("    },")

    # gfx: one stub per tile
    lines.append("    gfx = {")
    for i, t in enumerate(tiles):
        comma = "," if i < len(tiles) - 1 else ""
        lines.append(f'        {{0,0,0,0,0,0,0,0}}{comma}  -- [{i}] id:{t["id"]} char:{repr(t["char"])} ({t["type"]})')
    lines.append("    },")

    # info: type + colour
    lines.append("    info = {")
    for i, t in enumerate(tiles):
        comma = "," if i < len(tiles) - 1 else ""
        ttype = TILE_TYPE_MAP.get(t["type"], "T_HARM")
        col = color_hex(t["color"])
        lines.append(f'        {{colour={col},type={ttype}}}{comma}')
    lines.append("    }")
    lines.append("}")
    return lines


def emit_miner(idx: int, willy: dict | None) -> str:
    """Emit one minerStart entry."""
    if willy is None:
        return f'    {{x=1, y=13, frame=0, dir=D_RIGHT, ink=0x07}},  -- {idx} (no willy found)'
    dir_str = "D_LEFT" if willy["dir"] != 0 else "D_RIGHT"
    ink     = color_hex(willy["color"])
    return (f'    {{x={willy["x"]}, y={willy["y"]}, '
            f'frame={willy["frame"]}, dir={dir_str}, ink={ink}}},  -- {idx}')


def emit_robots(idx: int, robots: list) -> list[str]:
    """Emit one robotStartData level block."""
    lines = [f'    -- level {idx}', '    {']
    for r in robots:
        if r["etype"] == "dguard":
            lines.append(f'        -- SKIPPED dguard (unsupported): {r["raw"]}')
            continue
        move    = r["move"]
        nframes = NFRAMES.get(move, 7)
        frame   = START_FRAME.get(move, 0)
        ink     = color_hex(r["color"])
        min_px  = r["min"] * 8
        max_px  = r["max"] * 8
        lines.append(
            f'        {{x={r["x"]}, y={r["y"]}, '
            f'min={min_px}, max={max_px}, speed={r["speed"]}, '
            f'move="{move}", gfx=0, ink={ink}, '
            f'nframes={nframes}, frame={frame}, tile=0}},  '
            f'-- sprite_id:{r["sprite_id"]}'
        )
    lines.append('    },')
    return lines


def emit_portal(idx: int, portal: dict | None) -> str:
    """Emit one portalData entry."""
    stub_gfx = ",".join(["0"] * 16)
    if portal is None:
        return (f'    -- level {idx}: no portal found\n'
                f'    {{x=29, y=13, gfx={{{stub_gfx}}}, colour={{0x07,0x01}}}},')
    ink   = color_hex(portal["ink"])
    paper = color_hex(portal["paper"])
    return (f'    -- level {idx} (sprite_id:{portal["sprite_id"]})\n'
            f'    {{x={portal["x"]}, y={portal["y"]}, '
            f'gfx={{{stub_gfx}}}, colour={{{ink},{paper}}}}},')


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    ap = argparse.ArgumentParser(description="Convert Levels/*.txt → Lua snippets")
    ap.add_argument("files", nargs="*", help=".txt level files (default: Levels/*.txt)")
    ap.add_argument("--start-index", type=int, default=0,
                    help="Starting levelData index (default: 0)")
    ap.add_argument("--out-dir", default=".", help="Output directory (default: .)")
    args = ap.parse_args()

    # Collect input files
    if args.files:
        paths = sorted(args.files)
    else:
        base = os.path.join(os.path.dirname(__file__), "..", "Levels")
        paths = sorted(glob.glob(os.path.join(base, "*.txt")))

    if not paths:
        print("No .txt files found.", file=sys.stderr)
        sys.exit(1)

    os.makedirs(args.out_dir, exist_ok=True)
    out_levels = open(os.path.join(args.out_dir, "out_levels.lua"),  "w")
    out_miner  = open(os.path.join(args.out_dir, "out_miner.lua"),   "w")
    out_robots = open(os.path.join(args.out_dir, "out_robots.lua"),  "w")
    out_portal = open(os.path.join(args.out_dir, "out_portal.lua"),  "w")

    out_levels.write("-- Generated by convert_levels.py\n"
                     "-- Append to src/levels.lua\n"
                     "-- Fill in gfx arrays with real 8-byte Spectrum sprite data.\n\n")
    out_miner.write("-- Generated by convert_levels.py\n"
                    "-- Append these entries to the minerStart table in src/miner.lua\n\n")
    out_robots.write("-- Generated by convert_levels.py\n"
                     "-- Append these entries to the robotStartData table in src/robots.lua\n"
                     "-- Set gfx= to the correct robotSprite[] index for each enemy sprite.\n\n")
    out_portal.write("-- Generated by convert_levels.py\n"
                     "-- Append these entries to the portalData table in src/portal.lua\n"
                     "-- Fill in gfx arrays with real 16-word Spectrum portal sprite data.\n\n")

    idx = args.start_index
    ok = 0
    for path in paths:
        lv = parse_level(path)
        if lv is None:
            continue
        ents = parse_entities(lv["entities"])

        # levels.lua
        level_lines = emit_level(idx, lv)
        out_levels.write("\n".join(level_lines) + "\n\n")

        # miner.lua
        out_miner.write(emit_miner(idx, ents["willy"]) + "\n")

        # robots.lua
        robot_lines = emit_robots(idx, ents["robots"])
        out_robots.write("\n".join(robot_lines) + "\n")

        # portal.lua
        out_portal.write(emit_portal(idx, ents["portal"]) + "\n")

        print(f"  [{idx:3d}] {lv['name'][:30]:<30}  "
              f"tiles={len(lv['tiles'])}  robots={len([r for r in ents['robots'] if r['etype'] != 'dguard'])}  "
              f"portal={'yes' if ents['portal'] else 'no'}")
        idx += 1
        ok += 1

    out_levels.close()
    out_miner.close()
    out_robots.close()
    out_portal.close()

    print(f"\nConverted {ok} levels (indices {args.start_index}–{idx-1})")
    print(f"Output written to {os.path.abspath(args.out_dir)}/out_*.lua")


if __name__ == "__main__":
    main()
