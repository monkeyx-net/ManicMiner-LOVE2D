-- miner.lua: Player character (Miner Willy) logic

-- Start positions for each of the 20 levels
local minerStart = {
    {x=2,  y=13, frame=0, dir=D_RIGHT, ink=0x8},  -- 0
    {x=2,  y=13, frame=0, dir=D_RIGHT, ink=0x7},  -- 1
    {x=2,  y=13, frame=0, dir=D_RIGHT, ink=0x7},  -- 2
    {x=29, y=13, frame=0, dir=D_LEFT,  ink=0x4},  -- 3
    {x=1,  y=3,  frame=0, dir=D_RIGHT, ink=0x7},  -- 4
    {x=15, y=3,  frame=3, dir=D_LEFT,  ink=0x6},  -- 5
    {x=2,  y=13, frame=0, dir=D_RIGHT, ink=0x7},  -- 6
    {x=2,  y=13, frame=0, dir=D_RIGHT, ink=0x7},  -- 7
    {x=1,  y=13, frame=0, dir=D_RIGHT, ink=0x7},  -- 8
    {x=1,  y=4,  frame=0, dir=D_RIGHT, ink=0x7},  -- 9
    {x=3,  y=1,  frame=0, dir=D_RIGHT, ink=0x7},  -- 10
    {x=2,  y=13, frame=0, dir=D_RIGHT, ink=0x7},  -- 11
    {x=29, y=13, frame=0, dir=D_RIGHT, ink=0x7},  -- 12
    {x=29, y=13, frame=0, dir=D_RIGHT, ink=0x0},  -- 13
    {x=2,  y=13, frame=0, dir=D_RIGHT, ink=0x7},  -- 14
    {x=2,  y=13, frame=0, dir=D_RIGHT, ink=0x7},  -- 15
    {x=1,  y=3,  frame=3, dir=D_LEFT,  ink=0x7},  -- 16
    {x=29, y=13, frame=3, dir=D_LEFT,  ink=0x7},  -- 17
    {x=14, y=10, frame=0, dir=D_RIGHT, ink=0x5},  -- 18
    {x=27, y=13, frame=0, dir=D_LEFT,  ink=0x7},  -- 19
}

-- Jump stage info (18 stages)
local jumpInfo = {
    {y=-4, tile=-32, align=6, pitch=72, duration=5},
    {y=-4, tile=0,   align=4, pitch=74, duration=5},
    {y=-3, tile=-32, align=6, pitch=76, duration=4},
    {y=-3, tile=0,   align=6, pitch=78, duration=4},
    {y=-2, tile=0,   align=4, pitch=80, duration=3},
    {y=-2, tile=-32, align=6, pitch=82, duration=3},
    {y=-1, tile=0,   align=6, pitch=84, duration=2},
    {y=-1, tile=0,   align=6, pitch=86, duration=2},
    {y=0,  tile=0,   align=6, pitch=88, duration=1},
    {y=0,  tile=0,   align=6, pitch=88, duration=1},
    {y=1,  tile=0,   align=6, pitch=86, duration=2},
    {y=1,  tile=0,   align=6, pitch=84, duration=2},
    {y=2,  tile=32,  align=4, pitch=82, duration=3},
    {y=2,  tile=0,   align=6, pitch=80, duration=3},
    {y=3,  tile=0,   align=6, pitch=78, duration=4},
    {y=3,  tile=32,  align=4, pitch=76, duration=4},
    {y=4,  tile=0,   align=6, pitch=74, duration=5},
    {y=4,  tile=32,  align=4, pitch=72, duration=5},
}

-- Miner sprites: 8 frames x 16 rows (u16 values)
local minerSprite = {
    {96, 124, 62, 44, 124, 60, 24, 60, 126, 126, 239, 223, 60, 110, 118, 238},
    {384, 496, 248, 176, 496, 240, 96, 240, 504, 472, 472, 440, 240, 96, 96, 224},
    {1536, 1984, 992, 704, 1984, 960, 384, 960, 2016, 2016, 3824, 3568, 960, 1760, 1888, 3808},
    {6144, 7936, 3968, 2816, 7936, 3840, 1536, 3840, 8064, 16320, 32736, 28512, 7936, 23424, 28864, 8640},
    {24, 248, 496, 208, 248, 240, 96, 240, 504, 1020, 2046, 1782, 248, 474, 782, 900},
    {96, 992, 1984, 832, 992, 960, 384, 960, 2016, 2016, 3952, 4016, 960, 1888, 1760, 1904},
    {384, 3968, 7936, 3328, 3968, 3840, 1536, 3840, 7040, 7040, 7040, 7552, 3840, 1536, 1536, 1792},
    {1536, 15872, 31744, 13312, 15872, 15360, 6144, 15360, 32256, 32256, 63232, 64256, 15360, 30208, 28160, 30464},
}

-- Miner state (module-level)
local minerFrame, minerDir, minerMove
local minerAir, jumpStage
local minerInk

minerX    = 0   -- global (read by portal.lua)
minerY    = 0   -- global
minerTile = 0   -- global
minerAlign = 4  -- global

-- Sprite sequencing
local minerSeqIndex = 0
local minerSeqTimer = {}
local minerSequence = {0, 1, 2, 3, 7, 6, 5, 4}  -- 1-indexed

function Miner_SetSeq(index, speed)
    Timer_Set(minerSeqTimer, 1, speed)
    minerSeqIndex = minerSequence[index + 1]  -- +1 for 1-indexed
end

function Miner_IncSeq()
    minerSeqIndex = minerSeqIndex + Timer_Update(minerSeqTimer)
    minerSeqIndex = band(minerSeqIndex, 7)
end

function Miner_DrawSeqSprite(pos, paper, ink)
    local seqFrame = minerSequence[minerSeqIndex + 1]  -- +1 for 1-indexed
    Video_Sprite(pos, minerSprite[seqFrame + 1], paper, ink)
end

-- Internal: check if tile position is solid (blocks horizontal movement)
local function IsSolid(tile)
    if Level_GetTileType(tile) == T_SOLID then
        return true
    end
    if Level_GetTileType(tile + 32) == T_SOLID then
        return true
    end
    if Level_GetTileType(tile + 64) == T_SOLID then
        if minerAlign == 6 then
            return true
        end
        if minerAir == 1 and jumpStage > 9 then
            minerAir = 0
        end
    end
    return false
end

local function MoveLeftRight()
    if minerMove == 0 then return end

    if minerDir == D_LEFT then
        if minerFrame > 0 then
            minerFrame = minerFrame - 1
            return
        end
        if IsSolid(minerTile - 1) then return end
        minerTile = minerTile - 1
        minerX = minerX - 8
        minerFrame = 3
    else
        if minerFrame < 3 then
            minerFrame = minerFrame + 1
            return
        end
        if IsSolid(minerTile + 2) then return end
        minerTile = minerTile + 1
        minerX = minerX + 8
        minerFrame = 0
    end
end

function DoMinerTicker()
    local conveyDir = C_NONE

    if minerAir == 1 then
        local jump = jumpInfo[jumpStage + 1]  -- +1 for 1-indexed
        local tile = minerTile + jump.tile
        if Level_GetTileType(tile) == T_SOLID or Level_GetTileType(tile + 1) == T_SOLID then
            minerAir = 2
            minerMove = 0
            return
        end

        Audio_MinerSfx(jump.pitch, jump.duration)

        minerY = minerY + jump.y
        minerTile = tile
        minerAlign = jump.align
        jumpStage = jumpStage + 1

        if jumpStage == 18 then
            minerAir = 6
            return
        end

        if jumpStage ~= 13 and jumpStage ~= 16 then
            MoveLeftRight()
            return
        end
    end

    if minerAlign == 4 then
        local tile = minerTile + 64
        local type0 = Level_GetTileType(tile)
        local type1 = Level_GetTileType(tile + 1)

        if type0 == T_HARM or type1 == T_HARM then
            if minerAir == 1 and (type0 <= T_SPACE or type1 <= T_SPACE) then
                MoveLeftRight()
            else
                Action = Die_Action
            end
            return
        end

        if type0 > T_SPACE or type1 > T_SPACE then
            if minerAir >= 12 then
                Action = Die_Action
                return
            end

            -- Only collapse when player is standing on the tile
            if type0 == T_COLLAPSE then
                Level_CollapseTile(tile)
            end
            if type1 == T_COLLAPSE then
                Level_CollapseTile(tile + 1)
            end

            minerAir = 0

            if type0 == T_CONVEYL or type1 == T_CONVEYL then
                conveyDir = C_LEFT
            elseif type0 == T_CONVEYR or type1 == T_CONVEYR then
                conveyDir = C_RIGHT
            end

            local i = 0

            if System_IsKey(KEY_LEFT) == 1 or conveyDir == C_LEFT then i = i + 1 end
            if System_IsKey(KEY_RIGHT) == 1 or conveyDir == C_RIGHT then i = i + 2 end

            if i == 0 then
                minerMove = 0
            elseif i == 1 then
                if minerDir == D_RIGHT then
                    minerDir = D_LEFT
                    minerMove = 0
                else
                    minerMove = 1
                end
            elseif i == 2 then
                if minerDir == D_LEFT then
                    minerDir = D_RIGHT
                    minerMove = 0
                else
                    minerMove = 1
                end
            end

            if System_IsKey(KEY_JUMP) == 1 then
                minerAir = 1
                jumpStage = 0
            end

            MoveLeftRight()
            return
        end
    end

    if minerAir == 1 then
        MoveLeftRight()
        return
    end

    minerMove = 0
    if minerAir == 0 then
        minerAir = 2
        return
    end

    minerAir = minerAir + 1

    Audio_MinerSfx(78 - minerAir, 4)
    minerY = minerY + 4
    minerAlign = 4
    if band(minerY, 7) ~= 0 then
        minerAlign = 6
    else
        minerTile = minerTile + 32
    end
end

function DoMinerDrawer()
    local sprIdx = (minerDir * 4) + minerFrame + 1  -- 1-indexed
    if Video_Miner(bor(lshift(minerY, 8), minerX), minerSprite[sprIdx], minerInk) then
        Action = Die_Action
        return
    end

    -- Check harm tiles in occupied positions
    local tile = minerTile
    local adj = 1
    for i = 0, minerAlign - 1 do
        if Level_GetTileType(tile) == T_HARM then
            Action = Die_Action
            return
        end
        tile = tile + adj
        adj = bxor(adj, 30)
    end

    -- Pick up items and interact with tiles
    tile = minerTile
    adj = 1
    for i = 0, minerAlign - 1 do
        local ttype = Level_GetTileType(tile)
        if ttype == T_ITEM then
            Game_GotItem(tile)
        elseif ttype == T_SWITCHOFF then
            Level_Switch(tile)
        elseif ttype == T_SPACE then
            Level_SetSpgTile(tile, B_MINER)
        end
        tile = tile + adj
        adj = bxor(adj, 30)
    end
end

function Miner_Init()
    local start = minerStart[gameLevel + 1]  -- +1 for 1-indexed

    minerX     = start.x * 8
    minerY     = start.y * 8
    minerTile  = start.y * 32 + start.x
    minerAlign = 4
    minerFrame = start.frame
    minerDir   = start.dir
    minerMove  = 0
    minerAir   = 0
    minerInk   = start.ink
end
