-- trans.lua: Level transition (wipe + air score bonus)

local transLevel = 0

local function DoTransDrawer()
    if gameDemo == 0 then
        Game_DrawAir()
        Game_ExtraLife()
    end

    if transLevel > 0 then
        Video_LevelPaperFill(rshift(transLevel, 3))
        Video_LevelInkFill(band(transLevel, 0x7))
    end
end

local function DoTransTicker()
    if transLevel > 1 then
        transLevel = transLevel - 1
        return
    end

    if gameDemo == 0 then
        if transLevel == 1 then
            transLevel = transLevel - 1
            Audio_Sfx(SFX_AIR)
        end

        if gameAir > 8 then
            Game_ScoreAdd(8)
            Game_ReduceAir(8)
        elseif gameAir > 0 then
            Game_ScoreAdd(gameAir)
            Game_ReduceAir(gameAir)
        end

        if gameAirOld > 0 then
            return
        end
    end

    if gameLevel == TWENTY then
        gameLevel = 0
    else
        gameLevel = gameLevel + 1
    end

    Action = Game_Action
end

local function DoTransInit()
    transLevel = 63

    if gameDemo == 0 then
        Audio_Play(MUS_STOP)
    end

    Ticker = DoTransTicker
end

local function DoTransResponder()
    Action = Title_Action
end

function Trans_Action()
    Responder = (gameDemo ~= 0) and DoTransResponder or DoNothing
    Ticker    = DoTransInit
    Drawer    = DoTransDrawer
    Action    = DoNothing
end
