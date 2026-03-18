-- victory.lua: Victory screen (completing level 19 without cheat)

local victoryMinerSprite = {24,248,496,208,248,240,96,240,504,1020,2046,1782,248,474,782,900}

-- Swordfish sprite split into colour layers
local victorySwordfishCyan   = {672,1347,8164,29695,62200,7999,65508,16323, 0,0,0,0,0,0,0,0}      -- fish body
local victorySwordfishWhite  = {0,0,0,0,0,0,0,0, 0,0,0,0,0,32766,0,0}                            -- sword blade
local victorySwordfishYellow = {0,0,0,0,0,0,0,0, 0,256,14844,28418,20737,0,14844,256}             -- sword handle

local function DrawSwordfish(pos)
    for row = 0, 15 do
        Video_PixelFill(pos + row * WIDTH, 16, 0)   -- black background
    end
    Video_SpriteBlend(pos, victorySwordfishCyan,   5)
    Video_SpriteBlend(pos, victorySwordfishWhite,  7)
    Video_SpriteBlend(pos, victorySwordfishYellow, 6)
end

local victoryTimer = 0

local VICTORY_STEP = 3  -- 450 ticks → 150 game ticks (~2.5s instead of 7.5s)

local function DoVictoryTicker()
    victoryTimer = victoryTimer - VICTORY_STEP
    if victoryTimer <= 0 then
        Action = Trans_Action
    end
end

local function DoVictoryInit()
    System_Border(0)

    Portal_Init()
    Level_Drawer()
    Robots_Drawer()
    Portal_Drawer()

    Video_SpriteBlend(24 * WIDTH + 19 * 8, victoryMinerSprite, 0x7)
    DrawSwordfish(40 * WIDTH + 19 * 8)

    victoryTimer = 50 * 9

    Audio_Play(MUS_STOP)
    Audio_Sfx(SFX_VICTORY)

    Ticker = DoVictoryTicker
end

function Victory_Action()
    SetState(DoNothing, DoVictoryInit, DoNothing, DoNothing)
end
