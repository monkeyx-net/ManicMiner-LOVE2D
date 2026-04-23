-- common.lua: constants shared across all modules

-- LuaJIT bit library (Love2D 11.x uses LuaJIT / Lua 5.1)
local _bit = require("bit")
band   = _bit.band
bor    = _bit.bor
bxor   = _bit.bxor
lshift = _bit.lshift
rshift = _bit.rshift

WIDTH  = 256
HEIGHT = 192

TICKRATE   = 60    -- game logic rate (fixed, do not change)
TARGET_FPS = 30    -- render frame rate (set lower on weak devices, e.g. 30)
SAMPLERATE = 22050

-- Pixel buffer flags (videoPixel[])
B_LEVEL = 1   -- level tile ink pixel
B_ROBOT = 2   -- robot sprite pixel
B_MINER = 4   -- miner sprite pixel

-- TILE2PIXEL: convert tile index (0..511) to pixel position
function TILE2PIXEL(t)
    return bor(lshift(band(t, 992), 6), lshift(band(t, 31), 3))
end

-- Special pixel positions
KEYBOARD = 128 * WIDTH   -- piano keyboard draw position
LIVES    = 150 * WIDTH + 4
SCORE    = 172 * WIDTH

-- Key codes (matches C enum order)
KEY_LEFT   = 0
KEY_RIGHT  = 1
KEY_JUMP   = 2
KEY_ENTER  = 3
KEY_LSHIFT = 4
KEY_RSHIFT = 5
KEY_0      = 6
KEY_1      = 7
KEY_2      = 8
KEY_3      = 9
KEY_4      = 10
KEY_5      = 11
KEY_6      = 12
KEY_7      = 13
KEY_8      = 14
KEY_9      = 15
KEY_ESCAPE = 16
KEY_PAUSE  = 17
KEY_MUTE   = 18
KEY_ELSE   = 19
KEY_NONE   = 20
KEY_S      = 21
KEY_U      = 22
KEY_O      = 23
KEY_UP     = 24
KEY_DOWN   = 25
KEY_R      = 26
KEY_L      = 27
KEY_DELETE = 28

-- Key mapping: key code -> Love2D key name
keyMap = {
    [KEY_LEFT]   = "left",
    [KEY_RIGHT]  = "right",
    [KEY_UP]     = "up",
    [KEY_DOWN]   = "down",
    [KEY_JUMP]   = "space",
    [KEY_ENTER]  = "return",
    [KEY_LSHIFT] = "lshift",
    [KEY_RSHIFT] = "rshift",
    [KEY_0]      = "1",
    [KEY_1]      = "2",
    [KEY_2]      = "3",
    [KEY_3]      = "4",
    [KEY_4]      = "5",
    [KEY_5]      = "6",
    [KEY_6]      = "7",
    [KEY_7]      = "8",
    [KEY_8]      = "9",
    [KEY_9]      = "0",
}

-- Tile types (game.h enum)
T_ITEM     = 0
T_SWITCHOFF = 1
T_SWITCHON  = 2
T_SPACE    = 3
T_SOLID    = 4
T_FLOOR    = 5
T_COLLAPSE = 6
T_CONVEYL  = 7
T_CONVEYR  = 8
T_HARM     = 9
T_VOID     = 10

-- Conveyor directions
C_NONE  = 0
C_LEFT  = 1
C_RIGHT = 2

-- Special level indices
EUGENE = 4
SKYLAB = 13
SPG    = 18
TWENTY = 19

-- SPG tile types (for spg.lua)
B_SPG   = 8    -- SPG tile flag in videoPixel

-- Miner directions
D_RIGHT = 0
D_LEFT  = 1
D_JUMP  = 2

-- Audio constants
MUS_TITLE = 0
MUS_GAME  = 1
MUS_STOP  = 0
MUS_PLAY  = 1

SFX_DIE     = 0
SFX_KONG    = 1
SFX_GAMEOVER = 2
SFX_AIR     = 3
SFX_VICTORY = 4
SFX_NONE    = 5

-- 16-color palette (r,g,b in 0..1 range)
palette = {
    {0x00/255, 0x00/255, 0x00/255},  -- 0: black
    {0x00/255, 0x00/255, 0xff/255},  -- 1: blue
    {0xff/255, 0x00/255, 0x00/255},  -- 2: red
    {0xff/255, 0x00/255, 0xff/255},  -- 3: magenta
    {0x00/255, 0xff/255, 0x00/255},  -- 4: green
    {0x00/255, 0xaa/255, 0xff/255},  -- 5: light blue
    {0xff/255, 0xff/255, 0x00/255},  -- 6: yellow
    {0xff/255, 0xff/255, 0xff/255},  -- 7: white
    {0x80/255, 0x80/255, 0x80/255},  -- 8: mid grey
    {0x00/255, 0x55/255, 0xff/255},  -- 9: mid blue
    {0xaa/255, 0x00/255, 0x00/255},  -- A: mid red
    {0x55/255, 0x00/255, 0x00/255},  -- B: dark red
    {0x00/255, 0xaa/255, 0x00/255},  -- C: mid green
    {0x00/255, 0x55/255, 0x00/255},  -- D: dark green
    {0xff/255, 0x80/255, 0x00/255},  -- E: orange
    {0x80/255, 0x40/255, 0x00/255},  -- F: brown
}

-- Global state machine function pointers (Lua functions)
Action    = nil
Responder = nil
Ticker    = nil
Drawer    = nil

function DoNothing() end

function SetState(responder, ticker, drawer, action)
    Responder = responder
    Ticker    = ticker
    Drawer    = drawer
    Action    = action
end

function DoQuit()
    love.event.quit()
end

-- Frame counter incremented once per love.update; used by drawers to
-- skip redundant work when multiple ticks fire in the same render frame.
frameCount = 0

-- gameInput: set by keypressed, consumed by Responder
gameInput = KEY_NONE

-- Active gamepad (set by love.joystickadded / love.joystickremoved in main.lua)
activeGamepad = nil

-- Analog stick dead zone
local AXIS_THRESHOLD = 0.5

-- Check if a key is currently held (keyboard or gamepad).
-- During playback, returns the recorded input instead of querying hardware.
function System_IsKey(key)
    if replayMode == REPLAY_PLAYING then
        return Replay_IsKey(key)
    end

    local k = keyMap[key]
    local held = k and love.keyboard.isDown(k) or false

    if not held and activeGamepad then
        if key == KEY_LEFT then
            held = activeGamepad:isGamepadDown("dpleft")
                or activeGamepad:getGamepadAxis("leftx") < -AXIS_THRESHOLD
        elseif key == KEY_RIGHT then
            held = activeGamepad:isGamepadDown("dpright")
                or activeGamepad:getGamepadAxis("leftx") > AXIS_THRESHOLD
        elseif key == KEY_JUMP then
            held = activeGamepad:isGamepadDown("a")
                or activeGamepad:isGamepadDown("b")
        end
    end

    return held and 1 or 0
end

-- Replay mode constants (shared with replay.lua and common.lua)
REPLAY_NONE      = 0
REPLAY_RECORDING = 1
REPLAY_PLAYING   = 2

-- Border color (drawn around the game viewport)
borderColor = {0, 0, 0}

function System_Border(index)
    local c = palette[index + 1]
    borderColor[1] = c[1]
    borderColor[2] = c[2]
    borderColor[3] = c[3]
end
