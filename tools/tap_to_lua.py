#!/usr/bin/env python3
"""
tap_to_lua.py — Extract Manic Miner level data from a ZX Spectrum TAP file
and write it as a Lua table in the format:

    levelData[N] = {
        name  = "...",
        data  = { ... },   -- 32x16 tile indices (items stamped in)
        gfx   = { ... },   -- 8-byte pixel rows per tile type
        info  = { ... },   -- colour attr + tile type per slot
        items = { ... },   -- per-item colour, row, col
    }

Usage:
    python3 tap_to_lua.py <input.tap> [output.lua]

If output is omitted it defaults to <input_stem>_levels.lua.
"""

import sys
import os
from collections import Counter


# ---------------------------------------------------------------------------
# TAP parsing
# ---------------------------------------------------------------------------

def parse_tap(path: str) -> list[bytes]:
    """Return list of raw block payloads (flag byte stripped, checksum stripped)."""
    blocks = []
    with open(path, "rb") as f:
        data = f.read()
    pos = 0
    while pos + 2 <= len(data):
        block_len = data[pos] | (data[pos + 1] << 8)
        pos += 2
        if pos + block_len > len(data):
            break
        payload = data[pos : pos + block_len]
        pos += block_len
        blocks.append(payload)
    return blocks


def tap_header_info(block: bytes) -> dict | None:
    """Parse a TAP header block (flag=0x00). Returns None if not a header."""
    if not block or block[0] != 0x00 or len(block) < 18:
        return None
    type_names = {0: "Program", 1: "NumArray", 2: "CharArray", 3: "Code"}
    return {
        "type":      type_names.get(block[1], block[1]),
        "name":      block[2:12].decode("ascii", errors="replace").strip(),
        "data_len":  block[12] | (block[13] << 8),
        "load_addr": block[14] | (block[15] << 8),
        "param2":    block[16] | (block[17] << 8),
    }


def find_game_block(blocks: list[bytes]) -> tuple[bytes, int] | None:
    """
    Find the largest Code block — this is the main game data.
    Returns (data_bytes, load_address) with flag and checksum stripped,
    or None if not found.
    """
    best = None
    for i, blk in enumerate(blocks):
        hdr = tap_header_info(blk)
        if hdr and hdr["type"] == "Code":
            # The data block follows immediately
            if i + 1 < len(blocks):
                data_blk = blocks[i + 1]
                if data_blk and data_blk[0] == 0xFF:
                    payload = data_blk[1:-1]   # strip flag + checksum
                    if best is None or len(payload) > len(best[0]):
                        best = (payload, hdr["load_addr"])
    return best


# ---------------------------------------------------------------------------
# Level location discovery
# ---------------------------------------------------------------------------

KNOWN_LEVEL_NAMES = [
    b"Central Cavern",
    b"The Cold Room",
    b"The Menagerie",
    b"Abandoned Uranium",
    b"Eugene",
    b"Processing Plant",
    b"The Vat",
    b"Miner Willy",
    b"Amoebatrons",
    b"The Endorian Forest",
    b"Ore Refinery",
    b"Skylab",
    b"The Bank",
    b"The Warehouse",
    b"Solar Power",
    b"The Final Barrier",
]

LEVEL_SIZE  = 0x400   # 1024 bytes per level
NAME_OFFSET = 0x200   # level name at +0x200 (32 bytes, space-padded)
NUM_LEVELS  = 20


def find_level_base(data: bytes) -> int | None:
    """
    Locate the offset within the game data block where level 0 starts.
    Tries known level names; falls back to scanning for 0x400-aligned blocks
    with a printable 32-byte name at +0x200.
    """
    # Search for any known name, then snap back to 0x400 alignment
    for name in KNOWN_LEVEL_NAMES:
        idx = data.find(name)
        if idx >= 0:
            # name is at idx; in the level block it's at offset NAME_OFFSET
            # So level 0 base = idx - NAME_OFFSET, but snap to 0x400
            approx_base  = idx - NAME_OFFSET
            aligned_base = (approx_base // LEVEL_SIZE) * LEVEL_SIZE
            # Walk backwards to find level 0
            base = aligned_base
            # Heuristic: level 0 starts within 10 levels of where we found the name
            for delta in range(0, 10 * LEVEL_SIZE, LEVEL_SIZE):
                candidate = aligned_base - delta
                if candidate < 0:
                    break
                chunk = data[candidate : candidate + LEVEL_SIZE]
                name_bytes = chunk[NAME_OFFSET : NAME_OFFSET + 32]
                if all(32 <= b < 127 for b in name_bytes) and any(b != 32 for b in name_bytes):
                    base = candidate
                    # keep looking further back; stop when no more valid name
                else:
                    break
            return base

    # Fallback: scan for 0x400-aligned blocks with printable names
    for off in range(0, len(data) - LEVEL_SIZE, LEVEL_SIZE):
        chunk = data[off : off + LEVEL_SIZE]
        name_bytes = chunk[NAME_OFFSET : NAME_OFFSET + 32]
        if (all(32 <= b < 127 for b in name_bytes)
                and name_bytes.strip() and b"\x00" not in name_bytes):
            return off
    return None


# ---------------------------------------------------------------------------
# Per-level extraction
# ---------------------------------------------------------------------------

def read_tile_entries(chunk: bytes) -> list[dict]:
    """
    Read 8 tile definitions from 0x220, stride 9: [colour_attr | 8 pixel bytes].
    Returns list of {'colour': int, 'gfx': list[int]}.
    """
    entries = []
    for i in range(8):
        off    = 0x220 + i * 9
        colour = chunk[off]
        gfx    = list(chunk[off + 1 : off + 9])
        entries.append({"colour": colour, "gfx": gfx})
    return entries


def parse_items(chunk: bytes) -> list[dict]:
    """
    Parse the item list at 0x26E.
    Each item: [attr][addr_lo][0x5C|0x5D][0x60|0x68][0xFF]
    addr is relative to 0x5C00; row = offset//32, col = offset%32.
    """
    items = []
    off   = 0x26E
    while off + 5 <= 0x300:
        a, b1, b2, b3, b4 = chunk[off], chunk[off+1], chunk[off+2], chunk[off+3], chunk[off+4]
        if b2 in (0x5C, 0x5D) and b3 in (0x60, 0x68) and b4 == 0xFF and a != 0xFF:
            addr   = (b2 << 8) | b1
            offset = addr - 0x5C00
            if 0 <= offset < 512:
                items.append({"colour": a, "row": offset // 32, "col": offset % 32})
            off += 5
        else:
            off += 1
    return items


# Fixed output ordering for gfx/info:
#   slot 0 = T_SPACE    ← entries[0]
#   slot 1 = T_CONVEYL  ← entries[4]
#   slot 2 = T_CONVEYR  ← entries[3] XOR 0xFF  (animated conveyor direction)
#   slot 3 = T_SOLID    ← entries[1]
#   slot 4 = T_FLOOR    ← entries[2]
#   slot 5 = T_HARM     ← entries[5]
#   slot 6 = T_ITEM     ← entries[6]  (item pickup sprite)
#   slot 7 = T_WILLY    ← guardian sprite at +0x2B4
#   slot 8 = item tile  ← entries[colour_match] (appended only when items exist)

GFX_ENTRY_ORDER = [0, 4, 3, 1, 2, 5, 6]          # entry indices; index 3 gets inverted
GFX_TYPE_NAMES  = [
    "T_SPACE", "T_CONVEYL", "T_CONVEYR",
    "T_SOLID", "T_FLOOR",   "T_HARM",   "T_ITEM",
]
ITEM_SENTINEL = 0xFE


def process_level(chunk: bytes) -> dict | None:
    """Extract all data from a 1024-byte level chunk."""

    # --- Name ---
    name_bytes = chunk[NAME_OFFSET : NAME_OFFSET + 32]
    name = "".join(chr(b) if 32 <= b < 127 else "" for b in name_bytes).strip()
    if not name:
        return None

    # --- Tile entries ---
    entries = read_tile_entries(chunk)

    # colour -> entry index (first occurrence wins)
    colour_to_entry: dict[int, int] = {}
    for i, e in enumerate(entries):
        if e["colour"] not in colour_to_entry:
            colour_to_entry[e["colour"]] = i

    # --- Items ---
    items    = parse_items(chunk)
    map_data = list(chunk[0:0x200])

    # Stamp item positions
    for it in items:
        map_data[it["row"] * 32 + it["col"]] = ITEM_SENTINEL

    # --- Build gfx / info in fixed order ---
    gfx_out:  list[list[int]] = []
    info_out: list[dict]      = []
    colour_to_out: dict[int, int] = {}

    for slot_idx, entry_idx in enumerate(GFX_ENTRY_ORDER):
        e      = entries[entry_idx]
        colour = e["colour"]
        gfx    = [b ^ 0xFF for b in e["gfx"]] if entry_idx == 3 else list(e["gfx"])
        if colour not in colour_to_out:
            colour_to_out[colour] = slot_idx
        gfx_out.append(gfx)
        info_out.append({"colour": colour, "type": GFX_TYPE_NAMES[slot_idx]})

    # Guardian / Willy sprite at +0x2B4
    willy_gfx = list(chunk[0x2B4 : 0x2BC])
    gfx_out.append(willy_gfx)
    info_out.append({"colour": 0x00, "type": "T_WILLY"})

    # Item pickup tile (appended last, only when items present)
    item_out_idx: int | None = None
    if items:
        item_colour = items[0]["colour"]
        ei          = colour_to_entry.get(item_colour, 6)
        item_gfx    = list(entries[ei]["gfx"])
        item_out_idx = len(gfx_out)
        gfx_out.append(item_gfx)
        info_out.append({"colour": item_colour, "type": "T_ITEM"})

    # --- Remap map bytes to output tile indices ---
    def map_byte(b: int) -> int:
        if b == ITEM_SENTINEL:
            return item_out_idx if item_out_idx is not None else 0
        return colour_to_out.get(b, 0)

    remapped = [map_byte(b) for b in map_data]

    return {
        "name":  name,
        "map":   remapped,
        "gfx":   gfx_out,
        "info":  info_out,
        "items": items,
    }


# ---------------------------------------------------------------------------
# Lua serialisation
# ---------------------------------------------------------------------------

LUA_HEADER = """\
-- Manic Miner level data extracted by tap_to_lua.py
-- Source: {source}
--
-- data[]  : 32x16 tile indices (row-major). Item positions are stamped in.
-- gfx[]   : 8 pixel rows per tile slot.
-- info[]  : colour = ZX Spectrum attr byte; type = tile behaviour constant.
-- items[] : per-collectible colour attr, row and col.
--
-- gfx / info slot order:
--   [1] T_SPACE    [2] T_CONVEYL  [3] T_CONVEYR  [4] T_SOLID
--   [5] T_FLOOR    [6] T_HARM     [7] T_ITEM      [8] T_WILLY
--   [9] item tile  (appended when the level contains collectibles)

local T_SPACE    = 0
local T_SOLID    = 1
local T_FLOOR    = 2
local T_HARM     = 3
local T_ITEM     = 4
local T_CONVEYL  = 5
local T_CONVEYR  = 6
local T_COLLAPSE = 7
local T_WILLY    = 8

levelData = {{}}
"""


def level_to_lua(lev_num: int, lv: dict) -> list[str]:
    lines = []
    name_escaped = lv["name"].replace("\\", "\\\\").replace('"', '\\"')
    lines.append(f'levelData[{lev_num}] = {{')
    lines.append(f'    name = "{name_escaped}",')

    # data
    lines.append("    data = {")
    for row in range(16):
        rv    = lv["map"][row * 32 : (row + 1) * 32]
        comma = "," if row < 15 else ""
        lines.append(f'        {",".join(str(v) for v in rv)}{comma}')
    lines.append("    },")

    # gfx
    lines.append("    gfx = {")
    for g_idx, g in enumerate(lv["gfx"]):
        comma = "," if g_idx < len(lv["gfx"]) - 1 else ""
        lines.append(f'        {{{",".join(str(b) for b in g)}}}{comma}')
    lines.append("    },")

    # info
    lines.append("    info = {")
    for i_idx, inf in enumerate(lv["info"]):
        comma = "," if i_idx < len(lv["info"]) - 1 else ""
        lines.append(f'        {{colour=0x{inf["colour"]:02x},type={inf["type"]}}}{comma}')
    lines.append("    },")

    # items
    lines.append("    items = {")
    for it_idx, it in enumerate(lv["items"]):
        comma = "," if it_idx < len(lv["items"]) - 1 else ""
        lines.append(
            f'        {{colour=0x{it["colour"]:02x},row={it["row"]},col={it["col"]}}}{comma}'
        )
    lines.append("    }")

    lines.append("}")
    return lines


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def extract(tap_path: str, lua_path: str) -> None:
    print(f"Reading {tap_path} …")
    blocks = parse_tap(tap_path)
    print(f"  {len(blocks)} TAP blocks found")

    result = find_game_block(blocks)
    if result is None:
        raise SystemExit("ERROR: could not find a Code block in the TAP file.")
    game_data, load_addr = result
    print(f"  Game data block: {len(game_data)} bytes at load address 0x{load_addr:04X}")

    level_base = find_level_base(game_data)
    if level_base is None:
        raise SystemExit("ERROR: could not locate level data within the game block.")
    print(f"  Level data starts at block offset 0x{level_base:04X} "
          f"(absolute address 0x{load_addr + level_base:04X})")

    levels = []
    for lev in range(NUM_LEVELS):
        off   = level_base + lev * LEVEL_SIZE
        if off + LEVEL_SIZE > len(game_data):
            break
        chunk = game_data[off : off + LEVEL_SIZE]
        lv    = process_level(chunk)
        if lv:
            levels.append(lv)
            print(f"  Level {lev:2d}: '{lv['name']}'  "
                  f"({len(lv['items'])} items, {len(lv['gfx'])} tile slots)")

    print(f"\nWriting {len(levels)} levels to {lua_path} …")
    source = os.path.basename(tap_path)
    lines  = LUA_HEADER.format(source=source).splitlines()
    lines.append("")
    for lev_num, lv in enumerate(levels):
        lines.extend(level_to_lua(lev_num, lv))
        lines.append("")

    with open(lua_path, "w") as f:
        f.write("\n".join(lines))
    print("Done.")


def main() -> None:
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    tap_path = sys.argv[1]
    if not os.path.isfile(tap_path):
        raise SystemExit(f"ERROR: file not found: {tap_path}")

    if len(sys.argv) >= 3:
        lua_path = sys.argv[2]
    else:
        stem     = os.path.splitext(os.path.basename(tap_path))[0]
        lua_path = f"{stem}_levels.lua"

    extract(tap_path, lua_path)


if __name__ == "__main__":
    main()
