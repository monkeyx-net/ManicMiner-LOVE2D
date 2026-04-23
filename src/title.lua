-- title.lua: Title screen

local MINER_POS = 80 * WIDTH + 29 * 8

-- Title screen pixel data (64 rows x 32 bytes = 2048 bytes, plus 256 piano bytes)
local titlePixels = {
      5,255,255,255,255,255,224,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,255,255,255,255,  0,  0,  0,  0,  0,  0,
      7,255,255,255,255,255,248,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  1,124,224,  7, 62,128,  0,  0,  0,  0,  0,
      3,255,255,255,255,255,208,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  1,187, 95,250,221,128,  0,  0,  0,  0,  0,
      1,255,255,255,255,255,224,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  3,215,191,253,235,192,  0,  0,  0,  0,  0,
      6,255,255,255,255,255,228,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  3,239,255,255,247,192,  0,  0,  0,  0,  0,
     11,255,255,255,255,255,208,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  7,255,255,255,255,224,  0,  0,  0,  0,  0,
      5,255,255,255,255,255,180,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  7,255,255,255,255,224,  0,  0,  0,  0,  0,
     42,255,255,255,255,255,248,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 15,255,255,255,255,240,  0,  0,  0,  0,  0,
     59,255,255,255,253,255,224,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 15, 63,  0,  0,240,240,  0,  0,  0,  0,  0,
     22,255,207,255,241,255,200,  0,  0,  0,  0,  0,  1,240,  0,  0,  0,  0,  0,  0,  0,  7,255,  0,  0,255,224,  0,  0,  0,  0,  0,
     29,255,225,255,199,255,180,  0,  0,  0,  0,  0,  7,248,  0,  0,  0,  0,  0,  0,  0,  0,255,126,126,223,  0,  0,  0,  0,  0,  0,
     31,255,226,127, 39,255,246,  0,  0,  0,  0,  0, 15,252,  0,  0,  0,  0,  0,  0,  0,  0,  7,126,126, 24,  0,  0,  0,  0,  0,  0,
      5,255,248,190, 15,207,200,  0,  0,  0,  0,  0, 30, 59,176,  0,  0,  0,  0,  0,  0,  0,223,126,126,251,  0,  0,  0,  0,  0,  0,
      3,255,252, 29, 63,255,208,  0,  0,  0,  0,  0, 29,215,216,  0,  0,  0,  0,  0,  0,  0,223,126,126,251,  0,  0,  0,  0,  0,  0,
      6,255,254,  0,127,255,184,  0,  0,  0,  0,  0, 11,239,232,  0,  0,  0,  0,  0,  0,  0, 24,126,126,224,  0,  0,  0,  0,  0,  0,
      3,255,255,  4,255,255,100,  0,  0,  0,  0,  0,  7,223,236,  0,  0,  0,  0,  0,  0,  0,255,  0,  0,255,  0,  0,  0,  0,  0,  0,
      3,249, 63,  1,255,255,  0,  0,  7,224,  0,  0, 15,223,220,  0,  0,  0,  0,  0,  0,  0,255,  0,  0,255, 34, 34,  0, 48, 12,  0,
      5,240,207, 10,255,255,  0,  0,127,254,  0,  0, 15,239,120,  0,  0,  0, 24,  0, 10, 48,  1,126,126, 28,119,119,  0, 80, 12,  0,
      5,239,  3, 43,255,208,  0,  0,127,254,  0,  0, 31,255,151,128,  0,  0,124, 56, 46,124,223,126,126,223,119,119,  0, 80,  4,  3,
     23,255,208, 93,255,248,  0,  0,127,254,  0,  0, 31,255,239, 92,112,  0,126, 56,174,124,223,126,126,223,255,255,  0,144, 12, 62,
     29,255,224, 85,255,192,  0,  0, 63,252,  0,  0, 14,127,238,222,248,  0,236,252,238,238,  7,126,126,128,255,255,  0,160,  8, 16,
     31,255,248, 85,255,128,  1,128, 63,252,  1,128, 15,191,238,222,248,102,254,238,102,254,255,126,126,255,119,119,  1, 32, 24,252,
     10,255,253, 85,255,  0,  7,128, 63,252,  1,224,  7,223,207,111,120,238,126,126,116,252,255,  0,  0,255,119,119, 63,255,255,255,
      7,255,254, 93,255,  0, 31,192, 63,252,  3,248,  3,143,135,191,240,238,108,124, 36, 56, 12,  0,  0,252,119,119,255,255,227,255,
      0,255,159,107,243,  0, 63,192, 31,248,  3,252,  0,  0,  0,  0,  0, 68,  7, 48, 52, 22,223,127,247,255,119,119, 60,207,255, 60,
      0,127, 15,170,244,  0,127,224, 31,248,  7,254,  0,  0,  0,  0,  0,104, 24,160, 20, 19,223,127,247,255,119,119,126,255,255,126,
      0, 62,  7,170,192,  0,255,224, 31,248,  7,255,  0,  0,  0,  0,  0, 18, 14,224, 28, 26,128, 32,  0,  0,119,119,239,255,255,239,
      0, 20,  2,171,192,  1,255,240, 31,248, 15,255,128,  0,  0,  0,  0, 62, 15,220, 24, 78,251,239,190,251,119,119,251,255,255,251,
      0,  0,  0,109,128,  1,255,240, 15,240, 15,255,128,  0,  0,  0, 66,104,134,142,  8,108,251,239,190,251,119,119,223,207,255,223,
      0,  0,  0,117,  0,  3,255,248, 15,240, 31,255,192,  0,  0,  1, 42, 12,160,198,  8,116,  3,  0,  0,192,119,119,247,255,255,247,
      0,  0,  0, 85,  0,  3,255,248, 15,240, 31,255,192,  0,  0,  0,164,  4, 64,192, 12,  4,223,253,247,223,119,119,126,127,254,126,
      0,  0,  0, 85,  0,  7,255,252, 15,240, 63,255,224,  0,  0, 18,255,255,224,192,255,  7,223,255,247,255,119,119, 60,  0,  0, 60,
      0,  0,  0,117,  0,  7,255,252,  7,224, 63,255,224,  0,  0, 73,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,
      0,  0,  0,173,  0,  1,255,254,  7,224,127,255,128,  0,  0, 63,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,
      0,  0,  0,174,  0,  0,127,254,  0,  0,127,254,  0,  0,  0,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,
      0,  0,  0,106,  0,  0, 31,255,  0,  0,255,248,  0,  0, 15,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,
      0,  0,  0, 90,  0,  0,  7,255,  3,192,255,224,  0,  0, 63,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,
      0,  0,  0, 86,  0,  0,  1,254, 31,248,127,128,  0,  0,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,
      0,  0,  0, 85,  0,  0,  0,124,127,254, 62,  0,  0, 15,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,
      0,  0,  0,117,  0,  0,  0, 24,255,255, 24,  0,  0,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,
      0,  0,  0,181,  0,  0,  0,  1,255,255,128,  0,  0, 31,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,
      0,  0,  0,173,  0,112,  0,  3,255,255,192,  0, 14, 15,255,253,255,255,255,255,255,255,255,255,255,255,249,255,255,255,255,255,
      0,  0,  6,173, 48,127,  0,  3,255,255,192,  0,254,  7,255,237,255,255,255,255,255,255,255,255,255,255,244,255,255,219,255,255,
      0,  0, 15,174,248,127,240,  7,255,255,224, 15,254,  7,255,235,255,255,255,255,255,255,255,255,239,255,224,255,255,231,255,255,
      0,  0,127,118,252,127,255,  7,255,255,224,255,254,  3,255,247,255,255,255,255,255,255,255,255,183,255,249,255,255,247,255,255,
      0,  1,255, 85,252,255,255,199,255,255,227,255,255,  1,255,255,255,255,255,255,255,255,255,255,215,255,243,255,255,255,255,255,
      0, 15,255, 69,254,255,255,207,255,255,243,255,255,  1,255,255,255,255,255,255,255,255,255,255,239,255,231,255,255,255,255,255,
      0, 31,255, 33,255,255,255,207,255,255,243,255,255,  0,255,255,255,255,255,255,255,255,255,255,255,255,228, 23,255,255,255,255,
      0, 63,254,  0,127,128,  0,  0,  7,192,  0,  0,  0,  0,255,255,255,255,255,255,255,255,255,255,255,255,241, 71,255,255,255,255,
      1,255,248,  8,127,207,  0,  0,  1,240,  0,  0,  0,  0,255,255,237,255,255,255,255,255,255,255,255,255,250,143,255,255,255,255,
      3,255,240,199, 63,255,192,  0,  7,224,  0,  0, 15,192,255,255,243,255,255, 63,252,255,255,255,255,255,249,  7,255,255,255,255,
     15,255,243,247,255,255,225,128,  3,240,  0,  1,255,252,255,255,247,255,252,  0,  0,  0, 31,255,255,255,248, 15,255,255,255,255,
     63,255,255,255,255,255,255,224,  1,128,  0, 63,255,255, 62,255,255,255,253,  0,  0,221,223,255,255,255,252, 31,255,255,255,255,
    255,255,255,255,255,255,255,240, 15,192,  3,255,255,255,193,255,255,255,240, 31,248,  0, 31,255,255,255,255,255,255,255,255,255,
    255,255,255,255,255,255,255,248,  3,240, 31,255,255,255,255,255,255,255,247,  7,224,119,127,255,255,255,255,255,255,255,255,255,
    255,255,255,255,255,255,255,254,  1,192,127,255,255,255,255,255,255,255,192, 33,132,  0,  1,255,255,255,255,255,255,255,252,  0,
    255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,221, 58, 92,221,221,255,255,255,255,255,255,255,253,221,
      7,255,  7,255,  7,255,240,127,255,255,255,255,255,240,112,127,255,240,  0, 60,188,  0,  0,127,240,  7,255,240,127,240,112,  0,
    119,255,119,255,119,255,247,127,255,255,255,255,255,247,119,127,255,247,119, 33, 12,119,119,127,247,119,255,247,127,247,119,119,
      0, 28,  0, 28,  7,252, 16, 28, 28,  1,192,  0, 31,192,  0, 65,252,  0,  0,  7,192,  0,  0,  0,  0,  0,  1,192, 31,240,  0,  0,
    221,221,221,221,223,253,221,221,221,221,221,221,223,221,221,221,253,221,221, 31,240,221,221,221,221,221,221,221,223,253,221,221,
      0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
    119,119,119,119,119,119,119,119,119,119,119,119,119,119,119,119,119,119,119,  0,  0,119,119,119,119,119,119,119,119,119,119,119,
      0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 63,252,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
    -- Piano row (256 bytes)
    255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,
    170,170,170,170,170,170,170,170,170,170,170,170,170,170,170,170,170,170,170,170,170,170,170,170,170,170,170,170,170,170,170,170,
     68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68,
     17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17,
      0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
      0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
      0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
      0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
}

-- Title colour data (256 + 32 bytes)
local titleColour = {
    0x5d,0xcd,0xcd,0xcd,0x4d,0x4d,0x5d,0x50,0x50,0x50,0x50,0x50,0x57,0x57,0x57,0x57,0x57,0x50,0x50,0x50,0x50,0x5e,0xfe,0xfe,0xfe,0xfe,0x5e,0x50,0x50,0x50,0x50,0x50,
    0x5d,0xcd,0xfd,0xfd,0xfd,0xcd,0x5d,0x50,0x50,0x57,0x50,0x50,0x57,0x57,0x57,0x57,0x57,0x50,0x50,0x50,0x50,0x5e,0x87,0xb9,0xb9,0x87,0x5e,0x50,0x50,0x52,0x52,0x50,
    0x5d,0xfd,0xfd,0xfe,0x4d,0x5d,0x56,0x56,0x56,0x56,0x56,0x56,0x57,0x57,0x57,0x57,0x57,0x53,0x52,0x57,0x56,0x51,0x87,0xb9,0xb9,0x87,0x57,0x57,0x52,0x52,0x52,0x52,
    0x50,0x5d,0x5d,0xfe,0x5d,0x56,0x56,0x56,0x56,0x56,0x56,0x56,0x56,0x50,0x50,0x5c,0x5c,0x5c,0x5c,0x5c,0x5c,0x5c,0x87,0x87,0x87,0x87,0x57,0x57,0x50,0x52,0x52,0x50,
    0x50,0x50,0x50,0xfe,0x50,0x56,0x56,0x56,0x56,0x56,0x56,0x56,0x56,0x5c,0x5c,0x5c,0x0c,0x0c,0x0c,0x0c,0x0c,0x0c,0x0c,0x0c,0x0c,0x0c,0x0c,0x0c,0x0c,0x0c,0x0c,0x0c,
    0x50,0x5c,0x5c,0xfe,0x5c,0x56,0x56,0x56,0x56,0x56,0x56,0x56,0x56,0x7c,0x0c,0x4c,0x0c,0x0c,0x0c,0x0c,0x0c,0x0c,0x0c,0x0c,0x4c,0x0c,0x7c,0x7c,0x0c,0x4c,0x0c,0x0c,
    0x1c,0x1c,0xfc,0xfc,0xfc,0x1c,0x1c,0x1c,0x17,0x17,0x1c,0x1c,0x1c,0x7c,0x4c,0x0c,0x4c,0x0c,0x6c,0xfc,0xfc,0x6c,0x6c,0x0c,0x0c,0x0c,0x7c,0x7c,0x0c,0x0c,0x6c,0x6c,
    0x6c,0x6c,0x6c,0x6c,0x6c,0x6c,0x6c,0x6c,0x6c,0x6c,0x6c,0x6c,0x6c,0x6c,0x6c,0x6c,0x6c,0x6c,0x6c,0xfc,0xfc,0x6c,0x6c,0x6c,0x6c,0x6c,0x6c,0x6c,0x6c,0x6c,0x6c,0x6c,
    -- Extra row (32 bytes)
    0xa6,0xa6,0xa6,0xa6,0xa6,0xa6,0xa6,0xa6,0xa6,0xa6,0xa6,0xa6,0xa6,0xa6,0xa6,0xa6,0xa6,0xa6,0xa6,0xa6,0xa6,0xa6,0xa6,0xa6,0xa6,0xa6,0xa6,0xa6,0xa6,0xa6,0xa6,0xa6,
}

local TEXT_32 = "                                "

-- textTicker[1] = Bug-Byte version, [2] = Software Projects version
local textTicker = {
    "\x01\x00\x02\x02" .. "M" .. "\x02\x06" .. "A" .. "\x02\x04" .. "N" .. "\x02\x05" .. "I" .. "\x02\x03" .. "C " .. "\x02\x05" .. "M" .. "\x02\x03" .. "I" .. "\x02\x02" .. "N" .. "\x02\x06" .. "E" .. "\x02\x04" .. "R   " ..
    "\x02\x07" .. "(C) Bug-Byte Ltd. 1983   By Matthew Smith" .. TEXT_32 ..
    "\x02\x05" .. "L to Load a Gaame - Cursor Keys/PAD = Left & Right   " .. "\x02\x06" .. "Space/A Button = Jump   " .. "\x02\x03" .. "Pause/Tab/X Button = Pause      " .. "\x02\x04" .. "Alt/Y Button = Tune On/Off     " .. "\x02\x05" .. "S/B Button = High Scores        " .. "\x02\x05" .. "Back + Start Buttons = Quit".. TEXT_32 ..
    "\x02\x07" .. "Guide " .. "\x02\x05" .. "M" .. "\x02\x03" .. "i" .. "\x02\x02" .. "n" .. "\x02\x06" .. "e" .. "\x02\x04" .. "r" .. "\x02\x07" .. " Willy through 20 " .. "\x02\x02" .. "lethal " .. "\x02\x07" .. "caverns ...",
}

local textEnd = {248 * -8, 257 * -8}

local gameVersion = 0  -- 0 = Bug-Byte, 1 = Software Projects
local textPos = WIDTH

function Title_ScreenCopy()
    Video_CopyBytes(titlePixels)
    Video_CopyColour(titleColour, 0, 256 + 32)
end

-- Copy only the 8 game tile rows of the title screen (not the 9th row which overlaps level content)
function Title_BGCopy()
    local pixel = 0
    for si = 1, 2048 do
        local byte = titlePixels[si] or 0
        for bit = 7, 0, -1 do
            videoPixel[pixel] = band(rshift(byte, bit), 1)
            pixel = pixel + 1
        end
    end
    Video_CopyColour(titleColour, 0, 256)
end

local function DoStartGame()
    Video_PixelFill(0, WIDTH * HEIGHT, 0)
    Video_PixelFill(128 * WIDTH, 16 * WIDTH, 0x7)
    Video_Write(137 * WIDTH + 3, "\x01\x07\x02\x01" .. "A I R")
    Video_PixelFill(144 * WIDTH, 48 * WIDTH, 0x0)
    Video_WriteLarge(SCORE, 4, "\x01\x00\x02\x06" .. "High .....0        " .. "\x02\x0e" .. "Score .....0")
    Game_GameReset()
    Game_Action()
end

local function DoTitleTicker()
    textPos = textPos - 2

    if textPos < textEnd[gameVersion + 1] and audioMusicPlaying == MUS_STOP then
        gameDemo = 1
        Action = DoStartGame
    end

    Miner_IncSeq()
end

local function DoTitleDrawer()
    Audio_Drawer()
    Video_WriteLarge(160 * WIDTH, textPos, textTicker[gameVersion + 1])
    Miner_DrawSeqSprite(MINER_POS, 0xa, 0x7)
end

local function DoTitleAction()
    if audioMusicPlaying == MUS_STOP then return end

    Ticker = DoTitleTicker
    Drawer = DoTitleDrawer
    Action = DoNothing
end

local function DoTitleInit()
    Video_PixelFill(0, WIDTH * HEIGHT, 0)
    Title_ScreenCopy()
    Video_PixelFill(72 * WIDTH, 72 * WIDTH, 0xa)
    Video_PixelFill(144 * WIDTH, 48 * WIDTH, 0x0)

    -- Piano key labels: special chars \x1a=white key, \x1b=space, \x1c=black key
    Video_WriteLarge(82 * WIDTH, 0, "\x01\x0a\x02\x07\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f\x10\x11\x12\x13\x14\x15\x16")

    Video_Write(80 * WIDTH + 21 * 8, "\x02\x00" .. "Starring...")
    Video_Write(88 * WIDTH + 22 * 8, "\x02\x06" .. "Miner Willy")

    Video_WriteLarge(104 * WIDTH, 6 * 8, "\x02\x00" .. "PRESS " .. "\x02\x06" .. "ENTER" .. "\x02\x00" .. " TO START")
    Video_WriteLarge(KEYBOARD, 4, "\x01\x00\x02\x07\x1a\x1b\x1c\x1a\x1b\x1b\x1c\x1a\x1b\x1c\x1a\x1b\x1b\x1c\x1a\x1b\x1c\x1a\x1b\x1b\x1c\x1a\x1b\x1c\x1a\x1b\x1b\x1c\x1a\x1b\x1c")

    textPos = WIDTH

    Miner_SetSeq(7, 8)
    Miner_DrawSeqSprite(MINER_POS, 0xa, 0x7)

    Audio_Music(MUS_TITLE, MUS_PLAY)

    Ticker = DoNothing
end

-- ---------------------------------------------------------------------------
-- Save/Load menu (5 slots, accessed with L from the title screen)

local saveLoadSel = 1

local function DrawSaveLoadSlots()
    Video_PixelFill(32 * WIDTH, 80 * WIDTH, 0)
    for i = 1, 5 do
        local row  = (32 + (i - 1) * 16) * WIDTH
        local info = SaveState_GetInfo(i)
        local sel  = (saveLoadSel == i)
        local text
        if info then
            local name = levelData[info.level].name
            if #name > 14 then name = name:sub(1, 13) .. "." end
            local ink = sel and "\x06" or "\x07"
            text = "\x01\x00\x02" .. ink ..
                   string.format("%sSLOT %d  %-14s L:%d",
                       sel and ">" or " ", i, name, info.lives)
        else
            local ink = sel and "\x05" or "\x03"
            text = "\x01\x00\x02" .. ink ..
                   string.format("%sSLOT %d  ---  EMPTY  ---",
                       sel and ">" or " ", i)
        end
        Video_WriteLarge(row, 8, text)
    end
end

local function DoSaveLoadInit()
    saveLoadSel = 1
    Video_PixelFill(0, WIDTH * HEIGHT, 0)
    Video_WriteLarge(8 * WIDTH, 92, "\x01\x00\x02\x06LOAD GAME")
    DrawSaveLoadSlots()
    Video_Write(112 * WIDTH + 4, "\x01\x00\x02\x03UP/DOWN = SELECT SLOT")
    Video_Write(120 * WIDTH + 4, "\x01\x00\x02\x07ENTER=LOAD  \x02\x02DEL=ERASE  \x02\x07ESC=BACK")
    Ticker = DoNothing
end

local function DoSaveLoadResponder()
    if gameInput == KEY_UP then
        saveLoadSel = (saveLoadSel - 2) % 5 + 1
        DrawSaveLoadSlots()
    elseif gameInput == KEY_DOWN then
        saveLoadSel = saveLoadSel % 5 + 1
        DrawSaveLoadSlots()
    elseif gameInput == KEY_ENTER then
        local saveData = SaveState_Load(saveLoadSel)
        if saveData then
            gameVersion = System_IsKey(KEY_LSHIFT)
            Robots_Version(gameVersion)
            gameDemo = 0
            Video_PixelFill(0, WIDTH * HEIGHT, 0)
            Video_PixelFill(128 * WIDTH, 16 * WIDTH, 0x7)
            Video_Write(137 * WIDTH + 3, "\x01\x07\x02\x01" .. "A I R")
            Video_PixelFill(144 * WIDTH, 48 * WIDTH, 0x0)
            Video_WriteLarge(SCORE, 4, "\x01\x00\x02\x06" .. "High .....0        " .. "\x02\x0e" .. "Score .....0")
            Game_StartWithSave(saveData)
        end
    elseif gameInput == KEY_DELETE then
        if SaveState_Exists(saveLoadSel) then
            SaveState_Delete(saveLoadSel)
            DrawSaveLoadSlots()
        end
    elseif gameInput == KEY_ESCAPE then
        Action = Title_Action
    end
end

local function SaveLoadMenu_Action()
    SetState(DoSaveLoadResponder, DoSaveLoadInit, DoNothing, DoNothing)
end

-- ---------------------------------------------------------------------------
-- Options menu
--
-- Always-visible items (sel 0, 1):
--   Row 48: LIVES
--   Row 64: LEVEL  (level name shown at row 80)
-- Conditional items appended in order, starting at row 96 (16 rows each):
--   PLAY REPLAY   (when an in-memory recording is available)
--   SAVE REPLAY   (when an in-memory recording is available)
--   DELETE REPLAY (when replay.dat exists on disk)

local optionSel   = 0
local optionLives = 3
local optionLevel = 0
local optionItems = {}  -- ordered list of visible item type strings (built at init)

-- Ink colour helpers: yellow when selected, white otherwise (for edit items);
-- red when selected, magenta otherwise (for destructive items).
local function editInk(sel)   return sel and "\x06" or "\x07" end
local function destInk(sel)   return sel and "\x02" or "\x03" end

local function DrawOptionsItems()
    -- Clear all possible item rows (rows 48–143)
    Video_PixelFill(48 * WIDTH, 96 * WIDTH, 0)

    Video_WriteLarge(48 * WIDTH, 16,
        "\x01\x00\x02" .. editInk(optionSel == 0) ..
        string.format("LIVES:  %d", optionLives))

    Video_WriteLarge(64 * WIDTH, 16,
        "\x01\x00\x02" .. editInk(optionSel == 1) ..
        string.format("LEVEL: %02d", optionLevel))

    Video_WriteLarge(80 * WIDTH, 24,
        "\x01\x00\x02\x05" .. levelData[optionLevel].name)

    -- Conditional items start at row 96, one per 16-row slot
    for i = 3, #optionItems do
        local item = optionItems[i]
        local row  = 96 + (i - 3) * 16
        local s    = (optionSel == i - 1)
        if item == "playreplay" then
            Video_WriteLarge(row * WIDTH, 16,
                "\x01\x00\x02" .. editInk(s) .. "PLAY REPLAY")
        elseif item == "savereplay" then
            Video_WriteLarge(row * WIDTH, 16,
                "\x01\x00\x02" .. editInk(s) .. "SAVE REPLAY")
        elseif item == "deletereplay" then
            Video_WriteLarge(row * WIDTH, 16,
                "\x01\x00\x02" .. destInk(s) .. "DELETE REPLAY")
        end
    end
end

local function DoOptionsInit()
    optionLives = gameConfigLives
    optionLevel = gameConfigLevel
    optionSel   = 0

    -- Build the ordered list of visible items
    optionItems = {"lives", "level"}
    if Replay_HasBuffer()  then optionItems[#optionItems + 1] = "playreplay"   end
    if Replay_HasBuffer()  then optionItems[#optionItems + 1] = "savereplay"   end
    if Replay_Exists()     then optionItems[#optionItems + 1] = "deletereplay" end

    Video_PixelFill(0, WIDTH * HEIGHT, 0)
    Video_WriteLarge(16 * WIDTH, math.floor((WIDTH - 7 * 8) / 2),
        "\x01\x00\x02\x06OPTIONS")

    DrawOptionsItems()

    -- Instructions in small text below all possible item rows.
    -- Worst case: 4 conditional items ending at row 159; instructions start at 162.
    Video_Write(162 * WIDTH + 4, "\x01\x00\x02\x03LEFT/RIGHT = CHANGE VALUE")
    Video_Write(171 * WIDTH + 4, "\x01\x00\x02\x03UP/DOWN = SWITCH SETTING")
    Video_Write(180 * WIDTH + 4, "\x01\x00\x02\x07ENTER = OK   ESC = CANCEL")

    Ticker = DoNothing
end

local function DoOptionsResponder()
    local maxSel = #optionItems - 1  -- 0-based

    if gameInput == KEY_UP or gameInput == KEY_DOWN then
        if gameInput == KEY_UP then
            optionSel = (optionSel - 1 + maxSel + 1) % (maxSel + 1)
        else
            optionSel = (optionSel + 1) % (maxSel + 1)
        end
        DrawOptionsItems()
    elseif gameInput == KEY_LEFT then
        if optionSel == 0 then
            optionLives = math.max(1, optionLives - 1)
            DrawOptionsItems()
        elseif optionSel == 1 then
            optionLevel = math.max(0, optionLevel - 1)
            DrawOptionsItems()
        end
    elseif gameInput == KEY_RIGHT then
        if optionSel == 0 then
            optionLives = math.min(9, optionLives + 1)
            DrawOptionsItems()
        elseif optionSel == 1 then
            optionLevel = math.min(19, optionLevel + 1)
            DrawOptionsItems()
        end
    elseif gameInput == KEY_ENTER then
        local item = optionItems[optionSel + 1]
        if item == "playreplay" then
            Replay_StartPlayback()
        elseif item == "savereplay" then
            Replay_Save()
            Action = Title_Action
        elseif item == "deletereplay" then
            Replay_Delete()
            Action = Title_Action
        else  -- lives or level
            gameConfigLives = optionLives
            gameConfigLevel = optionLevel
            GameConfig_Save()
            Action = Title_Action
        end
    elseif gameInput == KEY_ESCAPE then
        Action = Title_Action
    end
end

local function DoOptionsAction()
    SetState(DoOptionsResponder, DoOptionsInit, DoNothing, DoNothing)
end

local function DoTitleResponder()
    if gameInput == KEY_ENTER then
        gameVersion = System_IsKey(KEY_LSHIFT)
        Robots_Version(gameVersion)
        gameDemo = 0
        Action = DoStartGame
    elseif gameInput == KEY_L then
        Action = SaveLoadMenu_Action
    elseif gameInput == KEY_S then
        Action = HiScores_Action
    elseif gameInput == KEY_O then
        Action = DoOptionsAction
    elseif gameInput == KEY_ESCAPE then
        DoQuit()
    end
end

function Title_Action()
    SetState(DoTitleResponder, DoTitleInit, Audio_Drawer, DoTitleAction)
end

-- ---------------------------------------------------------------------------
-- High scores screen

local function DoHiScoresInit()
    Video_PixelFill(0, WIDTH * HEIGHT, 0x0)

    Video_WriteLarge(0, 6 * 8, "\x01\x00\x02\x06HIGH SCORES")

    local inks = {0x7, 0x5}
    for i = 0, 19 do
        local row = (16 + i * 8) * WIDTH
        local name = levelData[i].name
        local score = levelHiScores[i]
        local ink = inks[(i % 2) + 1]
        local inkCode = "\x01\x00\x02" .. string.char(ink)
        Video_Write(row,       inkCode .. string.format("%2d ", i + 1) .. name)
        Video_Write(row + 180, inkCode .. string.format("%6d", score))
    end

    Video_Write(184 * WIDTH, "\x01\x00\x02\x02PRESS ANY KEY TO RETURN")

    Ticker = DoNothing
end

local function DoHiScoresResponder()
    Action = Title_Action
end

function HiScores_Action()
    SetState(DoHiScoresResponder, DoHiScoresInit, DoNothing, DoNothing)
end
