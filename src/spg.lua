-- spg.lua: Solar Power Generator special level logic (level 18)

local spgBeamPath  = {}
local spgBeamCount = 0

function DoSpgDrawer()
    local bg = levelBG or 0

    -- Clear previous beam path before redrawing
    for i = 1, spgBeamCount do
        local t = spgBeamPath[i]
        if Level_GetTileType(t) == T_SPACE then
            Video_TilePaper(t, bg)
        end
    end
    spgBeamCount = 0

    local tile = 23
    local dir  = 32
    local air  = 0

    repeat
        spgBeamCount = spgBeamCount + 1
        spgBeamPath[spgBeamCount] = tile
        Video_TilePaper(tile, 0x6)
        Video_TileInk(tile, 0xe)

        local this = Level_GetSpgTile(tile)

        if band(this, B_ROBOT) ~= 0 then
            -- 16-bit signed XOR: toggles between 32 (down) and -1 (left)
            local d = bxor(band(dir, 0xFFFF), 0xFFDF)
            dir = (d >= 32768) and (d - 65536) or d
        end

        if band(this, B_MINER) ~= 0 then
            air = 8
        end

        tile = tile + dir
    until Level_GetTileType(tile) ~= T_SPACE

    Video_TileInk(tile, 0xe)

    Game_ReduceAir(air)
end
