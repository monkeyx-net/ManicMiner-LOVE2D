-- die.lua: Death sequence

local dieBlank = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
local dieLevel = 0

local function DoDieDrawer()
    Video_LevelInkFill(rshift(dieLevel, 1))
    Game_ExtraLife()
    Game_DrawAir()
end

local function DoDieTicker()
    dieLevel = dieLevel - 1
    if dieLevel > 0 then return end

    if gameLives == 0 then
        Action = Gameover_Action
        return
    end

    Video_Sprite(LIVES + (gameLives - 1) * 16, dieBlank, 0x0, 0x0)

    Action = Game_Action
end

local function DoDieInit()
    gameLives = gameLives - 1

    dieLevel = 15  -- 2 frames per colour index

    Video_LevelPaperFill(0x0)
    System_Border(0x0)
    Audio_Sfx(SFX_DIE)

    Ticker = DoDieTicker
end

function Die_Action()
    Responder = DoNothing
    Ticker    = DoDieInit
    Drawer    = DoDieDrawer
    Action    = DoNothing
end
