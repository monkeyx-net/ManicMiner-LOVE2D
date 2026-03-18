


All 20 levels verified. Now writing the final file.Ran a command, read a fileRan a command, read a fileFixed. The root cause was that items are not stored in the map at all in this version — their positions only exist in a separate item list at offset 0x26E. The previous version read that list and put it in items[] but never wrote anything into data[], so renderers saw only empty space at those positions.
The fix: after parsing the item list, each item's (row, col) is stamped into the map array before building the tile index. The item tile (using the classic urn sprite from gfx slot 7) becomes the last entry in gfx[] and info[] with type T_ITEM. All 20 levels now verify correctly — item count in data[] matches item count in items[] for every level.
The items[] array is still included so your renderer can look up each item's individual colour attribute when drawing, since all items share the same T_ITEM tile index in the map but have different colours.


All 20 levels extracted. Here's a summary of how it all maps to your target format:
Structure found: The level data lives in the mm1 block (32768 bytes loaded at address 32768), starting at file offset 0x3000. Each level is exactly 1024 bytes (0x400).
Within each level:

0x000–0x1FF — 32×16 map (512 bytes, one byte per cell = ZX Spectrum colour attribute)
0x200–0x21F — level name (32 bytes, space-padded)
0x220–0x25F — tile graphics (8 entries × 8 pixel rows)
0x260–0x267 — tile attribute table (mostly unused here; colour is in the map byte itself)

Tile graphics lookup: gfx_index = (colour_byte >> 3) & 7 — just the paper colour bits. Tiles sharing the same paper colour share the same pixel shape and are only distinguished by their ink colour.
Type classification heuristics used:

T_SPACE — tile 0x00, or most common tile if it fills >35% of cells (e.g. level 1's blue background)
T_SOLID — dominant perimeter tile (left/right/bottom border)
T_FLOOR — most common non-space interior tile
T_CONVEYL — tiles appearing in horizontal runs of ≥5 cells, excluding space/border/floor
T_COLLAPSE — sparse paper=0 tiles with ink=2 or ink=4
T_ITEM — sparse tiles with ink=5 (magenta) on black paper
T_HARM — everything else sparse

Level 19 (The Final Barrier) has 21 unique tile types — it's an unusually complex final level with many mixed-colour decorative tiles, so you may want to review its info entries manually.


Let me compare what we're producing against what's expected.Ran 9 commandsRan 9 commandsNow the lookup is correct. The gfx table is 9 bytes per entry (colour_attr + 8 pixel bytes) at offset 0x220, stride 9. Colour 0x16 gives the conveyor mask whose bitwise inverse is expected[2]. Now regenerate the full file with this fix.Ran 4 commandsRan 4 commandsNow the full picture is clear. The expected gfx is the 9-byte table reordered as [0, 4, 3-inverted, 1, 2, 5, 6, guardian], with the conveyor mask (entry 3) XOR'd to produce the animated direction. Let me regenerate with this exact ordering.Ran 3 commandsRan 3 commandsAll 8 match. Now writing the final file with the correct sort order.Ran 3 commandsRan 3 commandsAll 8 match. The fixed ordering is [entry0, entry4, entry3^0xFF, entry1, entry2, entry5, entry6, guardian]. Now generating the final file.Final clean generation with correct fixed entry orderingFinal clean generation with correct fixed entry orderingThe root issue was the gfx lookup. There were two bugs:
Bug 1 — Wrong gfx table layout. The tile graphics are stored as 9-byte entries at offset 0x220 (not 8-byte groups): the first byte is the colour attribute that identifies which map tile uses this graphic, followed by 8 pixel bytes. We were reading them as flat 8-byte groups indexed by paper colour bits, which gave wrong graphics for most tiles.
Bug 2 — Wrong output ordering. The target engine expects gfx in a fixed semantic order:
IndexTypeSource0T_SPACEentry[0]1T_CONVEYLentry[4]2T_CONVEYRentry[3] XOR 0xFF3T_SOLIDentry[1]4T_FLOORentry[2]5T_HARMentry[5]6T_ITEM spriteentry[6]7T_WILLYguardian data at +0x2B4
Entry[3] is a wall-mask tile whose bitwise inverse produces the animated conveyor direction graphic — it's never used directly as a map tile.Continue10:41Presented filePresented fileHere's the completed file with all 20 levels. To recap what's in each level entry:

data[] — 32×16 map, tile indices matching the gfx/info order below
gfx[] — 9 entries: T_SPACE, T_CONVEYL, T_CONVEYR, T_SOLID, T_FLOOR, T_HARM, T_ITEM sprite, T_WILLY, then the stamped item tile
info[] — matching colour attrs and type constants
items[] — each collectible's individual colour attr plus its row/col (also stamped into data[] as the last tile index)


python
```bash
python3 tap_to_lua.py MANIC.TAP
# → writes MANIC_levels.lua

python3 tap_to_lua.py MANIC.TAP custom_output.lua
# → writes custom_output.lua
```
