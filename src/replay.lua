-- replay.lua: Input recording and playback
--
-- Press R during gameplay to cycle states:
--   idle (no buffer) -> recording -> idle (has buffer) -> playing -> idle -> recording ...
--
-- Recording captures LEFT/RIGHT/JUMP per DoMinerTicker call.
-- Playback replays those inputs deterministically (game has no RNG).
-- Save/load to replay.dat so recordings persist across sessions.

local REPLAY_FILE = "replay.dat"

-- REPLAY_NONE / REPLAY_RECORDING / REPLAY_PLAYING are globals defined in common.lua

-- Global: read by System_IsKey in common.lua
replayMode = REPLAY_NONE

local buffer   = {}   -- recorded input bytes, one per DoMinerTicker call
local playTick = 1    -- next index to read during playback
local tickBits = 0    -- cached input for current playback tick

-- Start state saved when recording begins
local startLevel, startLives, startScore, startHi

local BIT_LEFT  = 1
local BIT_RIGHT = 2
local BIT_JUMP  = 4

-- Sample raw keyboard/gamepad state, bypassing the replay path
local function SampleBits()
    local l = (keyMap[KEY_LEFT]  and love.keyboard.isDown(keyMap[KEY_LEFT]))  or false
    local r = (keyMap[KEY_RIGHT] and love.keyboard.isDown(keyMap[KEY_RIGHT])) or false
    local j = (keyMap[KEY_JUMP]  and love.keyboard.isDown(keyMap[KEY_JUMP]))  or false

    if activeGamepad then
        if not l then
            l = activeGamepad:isGamepadDown("dpleft")
                or activeGamepad:getGamepadAxis("leftx") < -0.5
        end
        if not r then
            r = activeGamepad:isGamepadDown("dpright")
                or activeGamepad:getGamepadAxis("leftx") > 0.5
        end
        if not j then
            j = activeGamepad:isGamepadDown("a")
                or activeGamepad:isGamepadDown("b")
        end
    end

    return (l and BIT_LEFT or 0) + (r and BIT_RIGHT or 0) + (j and BIT_JUMP or 0)
end

-- Called at the start of every DoMinerTicker invocation.
-- Records or loads the input state for this tick.
function Replay_Tick()
    if replayMode == REPLAY_RECORDING then
        buffer[#buffer + 1] = SampleBits()

    elseif replayMode == REPLAY_PLAYING then
        if playTick <= #buffer then
            tickBits = buffer[playTick]
            playTick = playTick + 1
        else
            -- Buffer exhausted: hand control back to the player
            replayMode = REPLAY_NONE
        end
    end
end

-- Called by System_IsKey during playback instead of querying the hardware
function Replay_IsKey(key)
    if key == KEY_LEFT  then return band(tickBits, BIT_LEFT)  ~= 0 and 1 or 0 end
    if key == KEY_RIGHT then return band(tickBits, BIT_RIGHT) ~= 0 and 1 or 0 end
    if key == KEY_JUMP  then return band(tickBits, BIT_JUMP)  ~= 0 and 1 or 0 end
    return 0
end

-- R key handler: cycles idle -> recording -> idle -> playing -> idle -> recording ...
function Replay_ToggleR()
    if replayMode == REPLAY_RECORDING then
        -- Stop recording, save to disk
        replayMode = REPLAY_NONE
        Replay_Save()

    elseif replayMode == REPLAY_PLAYING then
        -- Stop playback and discard buffer so next R starts a fresh recording
        replayMode = REPLAY_NONE
        buffer = {}

    else
        -- Idle: play if we have a buffer, otherwise start recording
        if #buffer > 0 then
            Replay_StartPlayback()
        else
            Replay_StartRecording()
        end
    end
end

function Replay_StartRecording()
    startLevel = gameLevel
    startLives = gameLives
    startScore, startHi = Game_GetScores()
    buffer   = {}
    playTick = 1
    tickBits = 0
    replayMode = REPLAY_RECORDING
    -- Restart the current level from a clean state so the replay is reproducible
    Game_ChangeLevel()
end

function Replay_StartPlayback()
    -- Full game reset so the state machine, responder and miner ticker are all
    -- correct regardless of whether we are called from gameplay or the title menu.
    gameDemo = 0
    Game_GameReset()
    -- Restore the exact state captured when recording began
    gameLevel = startLevel
    gameLives = startLives
    Game_SetScores(startScore, startHi)
    replayMode = REPLAY_PLAYING
    playTick   = 1
    tickBits   = 0
    Game_Action()
end

-- OSD: draw a small indicator in the score line between the two score values
function Replay_DrawOSD()
    if replayMode == REPLAY_RECORDING then
        Video_Write(SCORE + 110, "\x01\x00\x02\x02REC")   -- red ink
    elseif replayMode == REPLAY_PLAYING then
        Video_Write(SCORE + 110, "\x01\x00\x02\x04PLY")   -- green ink
    else
        Video_Write(SCORE + 110, "\x01\x00\x02\x00   ")   -- clear
    end
end

-- Persist the current recording to disk
function Replay_Save()
    if #buffer == 0 then return end
    local lines = {
        "version=1",
        "level="   .. startLevel,
        "lives="   .. startLives,
        "score="   .. startScore,
        "hiscore=" .. startHi,
        "count="   .. #buffer,
    }
    local t = {}
    for i, v in ipairs(buffer) do t[i] = tostring(v) end
    lines[#lines + 1] = "inputs=" .. table.concat(t, ",")
    love.filesystem.write(REPLAY_FILE, table.concat(lines, "\n"))
end

-- True when there is an in-memory recording available
function Replay_HasBuffer()
    return #buffer > 0
end

-- True when a replay file exists on disk
function Replay_Exists()
    return love.filesystem.getInfo(REPLAY_FILE) ~= nil
end

-- Delete the replay file and clear the in-memory buffer
function Replay_Delete()
    love.filesystem.remove(REPLAY_FILE)
    buffer     = {}
    replayMode = REPLAY_NONE
end

-- Load a saved recording from disk; returns true on success
function Replay_Load()
    local data = love.filesystem.read(REPLAY_FILE)
    if not data then return false end
    local s = {}
    for line in data:gmatch("[^\n]+") do
        local k, v = line:match("^([^=]+)=(.+)$")
        if k then s[k] = v end
    end
    if s.version ~= "1" then return false end
    startLevel = tonumber(s.level)   or 0
    startLives = tonumber(s.lives)   or 3
    startScore = tonumber(s.score)   or 0
    startHi    = tonumber(s.hiscore) or 0
    buffer = {}
    if s.inputs then
        for v in s.inputs:gmatch("[^,]+") do
            buffer[#buffer + 1] = tonumber(v) or 0
        end
    end
    return #buffer > 0
end
