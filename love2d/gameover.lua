-- gameover.lua: Game over screen

local plinthSprite = {65535,29262,35409,43605,19026,4680,8772,10836,10836,10836,10836,10836,10836,10836,10836,10836}
local bootSprite   = {10944,13632,16320,2304,2304,8064,4224,4224,4480,8768,8376,22820,17474,17410,17410,65535}
local goMinerSprite = {96,992,1984,832,992,960,384,960,2016,2016,3952,4016,960,1888,1760,1904}

local bootTicks = 0

-- Text arrays (ink byte at positions 4, 8, 12, 16 for each)
local textGame = {"\x01\x00\x02", 0x0, "G ", "\x02", 0x0, "a ", "\x02", 0x0, "m ", "\x02", 0x0, "e"}
local textOver = {"\x01\x00\x02", 0x0, "O ", "\x02", 0x0, "v ", "\x02", 0x0, "e ", "\x02", 0x0, "r"}

local function makeColorText(baseColors, letters)
    -- Build the colored text string from a base color counter
    local parts = {}
    for i = 1, 4 do
        parts[i*2-1] = "\x02" .. string.char(band(baseColors[i], 0x7))
        parts[i*2] = letters[i]
    end
    return "\x01\x00" .. table.concat(parts)
end

function Gameover_DrawCheat()
    Video_Sprite(LIVES + WIDTH - 3 * 8, bootSprite, 0x0, 0x5)
end

local function DoGameoverDrawer()
    if bootTicks <= 96 then
        Video_Sprite(band(bootTicks, 126) * WIDTH + 15 * 8, bootSprite, 0x0, 0x7)
        Video_LevelPaperFill(rshift(band(bootTicks, 12), 2))
    end

    if bootTicks < 96 then return end

    local c = math.floor(bootTicks / 4)
    local gameStr = "\x01\x00\x02" .. string.char(band(c,   0x7)) .. "G " ..
                    "\x02"         .. string.char(band(c+1, 0x7)) .. "a " ..
                    "\x02"         .. string.char(band(c+2, 0x7)) .. "m " ..
                    "\x02"         .. string.char(band(c+3, 0x7)) .. "e"
    local overStr = "\x01\x00\x02" .. string.char(band(c+4, 0x7)) .. "O " ..
                    "\x02"         .. string.char(band(c+5, 0x7)) .. "v " ..
                    "\x02"         .. string.char(band(c+6, 0x7)) .. "e " ..
                    "\x02"         .. string.char(band(c+7, 0x7)) .. "r"

    Video_WriteLarge(48 * WIDTH, 7 * 8,  gameStr)
    Video_WriteLarge(48 * WIDTH, 18 * 8, overStr)
end

local function DoGameoverTicker()
    bootTicks = bootTicks + 1

    if bootTicks == 256 then
        Action = Title_Action
    end
end

local function DoGameoverInit()
    Game_CheckHighScore()

    Video_PixelFill(0, 128 * WIDTH, 0x0)
    Video_Sprite(112 * WIDTH + 15 * 8, plinthSprite, 0x0, 0x7)
    Video_Sprite(96  * WIDTH + 15 * 8, goMinerSprite, 0x0, 0x7)

    bootTicks = 0

    Audio_Play(MUS_STOP)
    Audio_Sfx(SFX_GAMEOVER)

    Ticker = DoGameoverTicker
end

function Gameover_Action()
    Responder = DoNothing
    Ticker    = DoGameoverInit
    Drawer    = DoGameoverDrawer
    Action    = DoNothing
end
