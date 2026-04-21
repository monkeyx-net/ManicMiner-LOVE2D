-- victory.lua: Victory screen (completing level 19 without cheat)

local victoryMinerSprite = {24,248,496,208,248,240,96,240,504,1020,2046,1782,248,474,782,900}

local victoryTimer = 0

local function DoVictoryTicker()
    if victoryTimer == 0 then
        Action = Trans_Action
    end
    victoryTimer = victoryTimer - 1
end

local function DoVictoryInit()
    System_Border(0)

    Level_Drawer()
    Robots_Drawer()
    Portal_SwordFish()

    Video_SpriteBlend(24 * WIDTH + 19 * 8, victoryMinerSprite, 0x7)

    victoryTimer = 5 * 60  -- 5 seconds

    Audio_Play(MUS_STOP)
    Audio_Sfx(SFX_VICTORY)

    Ticker = DoVictoryTicker
end

function Victory_Action()
    SetState(DoNothing, DoVictoryInit, DoNothing, DoNothing)
end
