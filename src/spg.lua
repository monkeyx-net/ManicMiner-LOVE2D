-- spg.lua: Solar Power Generator special level logic (level 18)

function DoSpgDrawer()
    local tile = 23
    local dir  = 32
    local air  = 0

    repeat
        Video_TilePaper(tile, 0x4)
        Video_TileInk(tile, 0x7)

        local this = Level_GetSpgTile(tile)

        if band(this, B_ROBOT) ~= 0 then
            dir = bxor(dir, bor(lshift(255, 8), 223))
        end

        if band(this, B_MINER) ~= 0 then
            air = 8
        end

        tile = tile + dir
    until Level_GetTileType(tile) ~= T_SPACE

    Video_TileInk(tile, 0x7)

    Game_ReduceAir(air)
end
