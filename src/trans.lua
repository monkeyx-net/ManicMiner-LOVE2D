-- trans.lua: Level transition (wipe + air score bonus)

local transLevel     = 0
local transLastFrame = -1   -- frameCount when we last drew the fill

local function DoTransDrawer()
    if gameDemo == 0 then
        Game_DrawAir()
        Game_ExtraLife()
    end

    -- Video_LevelFill is expensive: skip if we already drew this render frame
    if transLevel > 0 and frameCount ~= transLastFrame then
        transLastFrame = frameCount
        Video_LevelFill(rshift(transLevel, 3), band(transLevel, 0x7))
    end
end

local TRANS_STEP = 2  -- logical ticks advanced per game tick (halves draw calls)

local function DoTransTicker()
    for _ = 1, TRANS_STEP do
        if transLevel > 1 then
            transLevel = transLevel - 1
            -- continue to next step
        else
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
                    break  -- still counting air; draw current state and wait
                end

                Scores_UpdateLevel(gameLevel)
            end

            if gameLevel == TWENTY then
                gameLevel = 0
            else
                gameLevel = gameLevel + 1
            end

            Action = Game_Action
            break  -- state transition done
        end
    end
end

local function DoTransInit()
    transLevel = 63

    if gameDemo == 0 then
        Audio_Play(MUS_STOP)
        Audio_StopAllSfx()
    end

    Ticker = DoTransTicker
end

local function DoTransResponder()
    Action = Title_Action
end

function Trans_Action()
    SetState((gameDemo ~= 0) and DoTransResponder or DoNothing, DoTransInit, DoTransDrawer, DoNothing)
end
