-- victory.lua: Victory screen (completing level 19 without cheat)

local victoryMinerSprite = {24,248,496,208,248,240,96,240,504,1020,2046,1782,248,474,782,900}

local victoryTimer = 0

local function DoVictoryTicker()
    victoryTimer = victoryTimer - 1
    if victoryTimer == 0 then
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

    victoryTimer = 50 * 9

    Audio_Play(MUS_STOP)
    Audio_Sfx(SFX_VICTORY)

    Ticker = DoVictoryTicker
end

function Victory_Action()
    Responder = DoNothing
    Ticker    = DoVictoryInit
    Drawer    = DoNothing
    Action    = DoNothing
end
