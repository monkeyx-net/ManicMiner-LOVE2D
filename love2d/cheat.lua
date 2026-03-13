-- cheat.lua: Cheat code system

local cheatCode = "6031769"
local cheatPos  = 0

cheatEnabled = 0  -- global

local function DoCheatEnabled()
    local level = 0

    for i = 0, 9 do
        if System_IsKey(KEY_0 + i) == 1 then
            level = i + 1
            break
        end
    end

    if System_IsKey(KEY_ENTER) == 0 then
        Game_Pause(0)
        return
    end

    if level == 0 then return end

    if System_IsKey(KEY_LSHIFT) == 1 or System_IsKey(KEY_RSHIFT) == 1 then
        level = level + 10
    end

    level = level - 1
    if level == gameLevel and gameTicks == 0 then return end

    gameLevel = level
    Action = Game_ChangeLevel
end

local function DoCheatDisabled()
    local inputChar = string.char(gameInput - KEY_0 + string.byte('0'))
    if cheatCode:sub(cheatPos + 1, cheatPos + 1) ~= inputChar then
        cheatPos = 0
        Game_Pause(0)
        return
    end

    cheatPos = cheatPos + 1

    if cheatPos < #cheatCode then
        return
    end

    cheatEnabled = 1
    cheatPos = 0

    Gameover_DrawCheat()
    Cheat_Responder = DoCheatEnabled
end

Cheat_Responder = DoCheatDisabled  -- global function variable
