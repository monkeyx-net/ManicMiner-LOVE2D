-- video.lua: pixel-level rendering, matching the C original

-- The pixel buffer (collision flags): B_LEVEL=1, B_ROBOT=2, B_MINER=4
videoPixel = {}
for i = 0, WIDTH * HEIGHT - 1 do
    videoPixel[i] = 0
end

-- Love2D ImageData for actual pixel colors (created by Video_Init)
local imgData = nil
screenImage = nil  -- global so main.lua can draw it

-- Flag: image needs refresh
local imageDirty = false

-- Pre-computed pixel offsets within a tile for point 0..63
-- offset = (row * WIDTH) + col  where row = point>>3, col = point&7
local tilePixelOffset = {}
do
    for point = 0, 63 do
        tilePixelOffset[point] = bor(band(lshift(point, 5), 0x700), band(point, 7))
    end
end

function Video_Init()
    imgData = love.image.newImageData(WIDTH, HEIGHT)
    screenImage = love.graphics.newImage(imgData)
    screenImage:setFilter("nearest", "nearest")
end

-- Set a single pixel color by palette index
function System_SetPixel(pos, index)
    local x = pos % WIDTH
    local y = math.floor(pos / WIDTH)
    if x < 0 or x >= WIDTH or y < 0 or y >= HEIGHT then return end
    local c = palette[index + 1]
    imgData:setPixel(x, y, c[1], c[2], c[3], 1)
    imageDirty = true
end

-- Flush the ImageData to the GPU texture
function Video_Flush()
    if imageDirty then
        screenImage:replacePixels(imgData)
        imageDirty = false
    end
end

-- Draw the screen image scaled to fit the window
function Video_Draw()
    Video_Flush()
    local ww, wh = love.graphics.getDimensions()
    -- compute viewport (letterbox/pillarbox)
    local sx, sy, sw, sh = Video_Viewport(ww, wh)
    love.graphics.setColor(borderColor[1], borderColor[2], borderColor[3])
    love.graphics.rectangle("fill", 0, 0, ww, wh)
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(screenImage, sx, sy, 0, sw / WIDTH, sh / HEIGHT)
end

-- Compute letterbox viewport
function Video_Viewport(ww, wh)
    local sw, sh
    if wh * 4 / 3 <= ww then
        sh = math.floor(HEIGHT * wh / (HEIGHT + 16))
        sw = math.floor(sh * 4 / 3)
    else
        sw = math.floor(WIDTH * ww / (WIDTH + 16))
        sh = math.floor(sw * 3 / 4)
    end
    local sx = math.floor((ww - sw) / 2)
    local sy = math.floor((wh - sh) / 2)
    return sx, sy, sw, sh
end

-- Clear sprite pixels (B_ROBOT, B_MINER) from the game area, restore to level background.
-- Must be called before Level_Drawer each frame so old sprite positions are erased.
function Video_ClearSprites()
    local GAME_PIXELS = 128 * WIDTH
    local mask = bor(B_ROBOT, B_MINER)
    local bg = levelBG or 0
    for i = 0, GAME_PIXELS - 1 do
        local f = videoPixel[i]
        if band(f, mask) ~= 0 then
            videoPixel[i] = 0
            System_SetPixel(i, bg)
        end
    end
end

-- Fill a region of pixels with a solid color (clears collision flags too)
function Video_PixelFill(pixel, size, ink)
    for i = 0, size - 1 do
        videoPixel[pixel + i] = 0
        System_SetPixel(pixel + i, ink)
    end
end

-- Draw an 8x8 tile at pixel position pos (top-left)
-- gfx: array [1..8] of bytes (each byte = one row, bit7=left)
-- rows: number of rows to draw (usually 8)
function Video_Tile(pos, gfx, paper, ink, rows)
    for row = 0, rows - 1 do
        local pixel = pos + row * WIDTH
        local byte = gfx[row + 1] or 0
        for bit = 0, 7 do
            local px = pixel + (7 - bit)
            local v = band(rshift(byte, bit), 1)
            videoPixel[px] = v * B_LEVEL
            if v == 0 then
                System_SetPixel(px, paper)
            else
                System_SetPixel(px, ink)
            end
        end
    end
    return pos + rows * WIDTH
end

-- Draw a level tile at tile index tile
-- (pos already set up to be the top-left pixel)
-- Same as Video_Tile but using tile's 8x8 gfx
function Video_TileAt(tile, tileGfx, paper, ink)
    local pos = TILE2PIXEL(tile)
    Video_Tile(pos, tileGfx, paper, ink, 8)
end

-- Set paper (background) color for all paper pixels in a tile
function Video_TilePaper(tile, paper)
    local pixel = TILE2PIXEL(tile)
    for point = 0, 63 do
        local pos = pixel + tilePixelOffset[point]
        if band(videoPixel[pos], B_LEVEL) == 0 then
            System_SetPixel(pos, paper)
        end
    end
end

-- Set ink (foreground) color for all ink pixels in a tile
function Video_TileInk(tile, ink)
    local pixel = TILE2PIXEL(tile)
    for point = 0, 63 do
        local pos = pixel + tilePixelOffset[point]
        if band(videoPixel[pos], B_LEVEL) ~= 0 then
            System_SetPixel(pos, ink)
        end
    end
end

-- Fill all 512 tiles with paper color
function Video_LevelPaperFill(paper)
    for tile = 0, 511 do
        Video_TilePaper(tile, paper)
    end
end

-- Fill all 512 tiles with ink color
function Video_LevelInkFill(ink)
    for tile = 0, 511 do
        Video_TileInk(tile, ink)
    end
end

-- Draw a 16x16 sprite (u16[16]) at pixel position pos (top-left)
-- Bits drawn right-to-left (pos+15 = bit0, pos+0 = bit15)
function Video_Sprite(pos, gfx, paper, ink)
    local startpos = pos + 15
    for row = 0, 15 do
        local pixel = startpos + row * WIDTH
        local word = gfx[row + 1] or 0
        for bit = 0, 15 do
            local v = band(word, 1)
            videoPixel[pixel] = v  -- 0 or B_LEVEL(1)
            if v == 0 then
                System_SetPixel(pixel, paper)
            else
                System_SetPixel(pixel, ink)
            end
            pixel = pixel - 1
            word = rshift(word, 1)
        end
    end
end

-- Draw a 16x16 sprite blended (only ink pixels, marks as B_ROBOT)
function Video_SpriteBlend(pos, gfx, ink)
    local startpos = pos + 15
    for row = 0, 15 do
        local pixel = startpos + row * WIDTH
        local word = gfx[row + 1] or 0
        for bit = 0, 15 do
            if band(word, 1) ~= 0 then
                videoPixel[pixel] = bor(videoPixel[pixel], bor(B_ROBOT, 1))
                System_SetPixel(pixel, ink)
            end
            pixel = pixel - 1
            word = rshift(word, 1)
        end
    end
end

-- Draw the miner sprite (left-to-right, collision detect with robots)
-- Returns true if collision with robot detected (die)
function Video_Miner(pos, gfx, ink)
    local die = false
    for row = 0, 15 do
        local pixel = pos + row * WIDTH
        local word = gfx[row + 1] or 0
        for bit = 0, 15 do
            if band(word, 1) ~= 0 then
                if band(videoPixel[pixel], B_ROBOT) ~= 0 then
                    die = true
                end
                videoPixel[pixel] = bor(videoPixel[pixel], bor(B_MINER, 1))
                System_SetPixel(pixel, ink)
            end
            pixel = pixel + 1
            word = rshift(word, 1)
        end
    end
    return die
end

-- Air bar: draw 4 vertical pixels (a 1x4 vertical bar segment)
function Video_AirBar(pixel, ink)
    System_SetPixel(pixel, ink)
    System_SetPixel(pixel + WIDTH, ink)
    System_SetPixel(pixel + WIDTH * 2, ink)
    System_SetPixel(pixel + WIDTH * 3, ink)
end

-- Small charset: 96 chars (ASCII 32..127), variable width
-- Format: {width, col1, col2, ..., 0}  (each col = 8 pixels tall)
local charSet = {
    {3, 0, 0, 0},
    {2, 47, 0},
    {4, 3, 0, 3, 0},
    {7, 18, 63, 18, 18, 63, 18, 0},
    {6, 46, 42, 127, 42, 58, 0},
    {7, 35, 19, 8, 4, 50, 49, 0},
    {7, 16, 42, 37, 42, 16, 40, 0},
    {2, 3, 0},
    {3, 30, 33, 0},
    {3, 33, 30, 0},
    {4, 20, 8, 20, 0},
    {4, 8, 28, 8, 0},
    {2, 96, 0},
    {4, 8, 8, 8, 0},
    {2, 32, 0},
    {4, 8, 42, 8, 0},    -- /
    {6, 12, 18, 33, 18, 12, 0},
    {4, 34, 63, 32, 0},
    {6, 50, 41, 41, 41, 38, 0},
    {6, 18, 33, 37, 37, 26, 0},
    {5, 15, 8, 60, 8, 0},
    {6, 23, 37, 37, 37, 25, 0},
    {6, 30, 37, 37, 37, 24, 0},
    {6, 1, 1, 49, 13, 3, 0},
    {6, 26, 37, 37, 37, 26, 0},
    {6, 6, 41, 41, 41, 30, 0},
    {2, 20, 0},
    {2, 52, 0},
    {4, 8, 20, 34, 0},
    {6, 20, 20, 20, 20, 20, 0},
    {4, 34, 20, 8, 0},
    {6, 2, 1, 41, 5, 2, 0},
    {7, 30, 33, 45, 43, 45, 14, 0},
    {6, 48, 14, 9, 14, 48, 0},
    {6, 63, 37, 37, 37, 26, 0},
    {6, 30, 33, 33, 33, 18, 0},
    {6, 63, 33, 33, 18, 12, 0},
    {6, 63, 37, 37, 37, 33, 0},
    {6, 63, 5, 5, 5, 1, 0},
    {6, 30, 33, 33, 41, 26, 0},
    {6, 63, 4, 4, 4, 63, 0},
    {4, 33, 63, 33, 0},
    {6, 16, 32, 32, 32, 31, 0},
    {6, 63, 4, 10, 17, 32, 0},
    {6, 63, 32, 32, 32, 32, 0},
    {8, 56, 7, 12, 16, 12, 7, 56, 0},
    {7, 63, 2, 4, 8, 16, 63, 0},
    {6, 30, 33, 33, 33, 30, 0},
    {6, 63, 9, 9, 9, 6, 0},
    {7, 30, 33, 41, 49, 33, 30, 0},
    {6, 63, 9, 9, 25, 38, 0},
    {6, 18, 37, 37, 37, 24, 0},
    {6, 1, 1, 63, 1, 1, 0},
    {6, 31, 32, 32, 32, 31, 0},
    {6, 7, 24, 32, 24, 7, 0},
    {8, 7, 24, 32, 24, 32, 24, 7, 0},
    {7, 33, 18, 12, 12, 18, 33, 0},
    {6, 3, 4, 56, 4, 3, 0},
    {7, 33, 49, 41, 37, 35, 33, 0},
    {3, 63, 33, 0},
    {6, 2, 4, 8, 16, 32, 0},
    {3, 33, 63, 0},
    {6, 4, 2, 63, 2, 4, 0},
    {6, 64, 64, 64, 64, 64, 0},
    {6, 36, 62, 37, 33, 34, 0},
    {5, 16, 42, 42, 60, 0},
    {5, 63, 34, 34, 28, 0},
    {5, 28, 34, 34, 34, 0},
    {5, 28, 34, 34, 63, 0},
    {5, 28, 42, 42, 36, 0},
    {4, 62, 5, 1, 0},
    {5, 28, 162, 162, 126, 0},
    {5, 63, 2, 2, 60, 0},
    {2, 61, 0},
    {4, 32, 64, 61, 0},
    {5, 63, 12, 18, 32, 0},
    {2, 63, 0},
    {6, 62, 2, 60, 2, 60, 0},
    {5, 62, 2, 2, 60, 0},
    {5, 28, 34, 34, 28, 0},
    {5, 254, 34, 34, 28, 0},
    {5, 28, 34, 34, 254, 128},
    {4, 60, 2, 2, 0},
    {5, 36, 42, 42, 16, 0},
    {4, 2, 63, 2, 0},
    {5, 30, 32, 32, 30, 0},
    {6, 6, 24, 32, 24, 6, 0},
    {6, 30, 32, 28, 32, 30, 0},
    {6, 34, 20, 8, 20, 34, 0},
    {5, 30, 160, 160, 126, 0},
    {6, 34, 50, 42, 38, 34, 0},
    {4, 4, 59, 33, 0},
    {2, 63, 0},
    {4, 33, 59, 4, 0},
    {5, 8, 4, 8, 4, 0},
    {9, 60, 66, 153, 165, 165, 129, 66, 60, 0}
}

-- Large charset: 128 entries, each 8 u16 words (for 16-row tall text)
local charSetLarge = {
    {0,0,0,0,0,0,0,0},{0,0,0,0,0,0,0,0},{0,0,0,0,0,0,0,0},
    {2048,2048,2048,2048,2048,2048,2048,2048},
    {768,1152,1024,1024,524,2578,2323,2189},
    {2125,2081,2065,2057,2053,2051,2175,2111},
    {2072,2060,2054,2563,3071,3071,2561,2048},
    {2560,2944,2784,2168,2126,2119,2142,2680},
    {3040,2944,2560,2048,2561,3071,3071,2566},
    {2060,2072,2096,2144,2241,2559,3071,2049},
    {2048,2561,3071,3071,2561,2048,2168,2300},
    {2510,2306,2561,2561,2561,2306,2311,2180},
    {2048,2048,2048,2048,2048,2048,2048,2048},
    {2048,2048,2048,2076,2082,2081,2065,2065},
    {2049,2561,3071,2563,2063,2108,2160,2080},
    {2072,2566,3071,3071,2561,2048,2561,3071},
    {3071,2561,2048,2561,3071,3071,2566,2060},
    {2072,2096,2144,2241,2559,3071,2049,2048},
    {2561,3071,3071,2577,2577,2577,2617,2819},
    {2819,2180,2048,2561,3071,3071,2577,2065},
    {2097,2161,2259,2463,782,1536,1536,1024},
    {1024,1216,704,2432,2048,2048,2048,2048},
    {2048,2048,2048,2048,0,0,0,0},
    {0,0,0,0,0,0,0,0},
    {0,0,0,0,0,0,0,0},
    {0,255,255,255,255,255,0,0},               -- 25: black note
    {65535,65535,65535,65535,65535,65280,65280,0}, -- 26: white note l
    {65280,65280,65535,65535,65535,65280,65280,0}, -- 27: white note m
    {65280,65280,65535,65535,65535,65535,65535,0}, -- 28: white note r
    {0,0,0,0,0,0,0,0},{0,0,0,0,0,0,0,0},{0,0,0,0,0,0,0,0},
    {0,0,0,0,0,0,0,0},  -- 32: space
    {0,0,60,7166,7166,60,0,0},
    {0,7,15,0,0,15,7,0},
    {528,8190,8190,528,8190,8190,528,0},
    {1592,3196,2116,6214,6214,4044,1928,0},
    {6158,7694,1920,480,120,7198,7174,0},
    {3968,8156,4222,4578,4030,8156,4160,0},
    {0,0,8,15,7,0,0,0},
    {0,0,2040,4092,6150,4098,0,0},
    {0,0,4098,6150,4092,2040,0,0},
    {128,672,992,448,992,672,128,0},
    {0,128,128,992,992,128,128,0},
    {0,0,8192,14336,6144,0,0,0},
    {128,128,128,128,128,128,128,0},
    {0,0,0,6144,6144,0,0,0},
    {6144,7680,1920,480,120,30,6,0},
    {2040,4092,6150,4098,6150,4092,2040,0},
    {0,4104,4108,8190,8190,4096,4096,0},
    {7684,7942,4482,4290,4194,6206,6172,0},
    {2052,6150,4162,4162,4162,8190,4028,0},
    {510,510,4352,8160,8160,4352,256,0},
    {2174,6270,4162,4162,4162,8130,3970,0},
    {4088,8188,4166,4162,4162,8128,3968,0},
    {6,6,7682,8066,450,126,62,0},
    {4028,8190,4162,4162,4162,8190,4028,0},
    {60,4222,4162,4162,6210,4094,2044,0},
    {0,0,0,3096,3096,0,0,0},
    {0,0,4096,7192,3096,0,0,0},
    {0,192,480,816,1560,3084,2052,0},
    {576,576,576,576,576,576,576,0},
    {0,2052,3084,1560,816,480,192,0},
    {12,14,2,7042,7106,126,60,0},
    {4088,8188,4100,5060,5060,5116,504,0},
    {8176,8184,140,134,140,8184,8176,0},
    {4098,8190,8190,4162,4162,8190,4028,0},
    {2040,4092,6150,4098,4098,6150,3084,0},
    {4098,8190,8190,4098,6150,4092,2040,0},
    {4098,8190,8190,4162,4322,6150,7182,0},
    {4098,8190,8190,4162,226,6,14,0},
    {2040,4092,6150,4226,4226,3974,8076,0},
    {8190,8190,64,64,64,8190,8190,0},
    {0,0,4098,8190,8190,4098,0,0},
    {3072,7168,4096,4098,8190,4094,2,0},
    {4098,8190,8190,192,1008,8126,7182,0},
    {4098,8190,8190,4098,4096,6144,7168,0},
    {8190,8190,28,120,28,8190,8190,0},
    {8190,8190,120,480,1920,8190,8190,0},
    {4092,8190,4098,4098,4098,8190,4092,0},
    {4098,8190,8190,4162,66,126,60,0},
    {4092,8190,4098,7170,30722,32766,20476,0},
    {4098,8190,8190,66,450,8190,7740,0},
    {3100,7230,4194,4162,4290,8078,3852,0},
    {14,6,4098,8190,8190,4098,6,14},
    {4094,8190,4096,4096,4096,8190,4094,0},
    {1022,2046,3072,6144,3072,2046,1022,0},
    {2046,8190,7168,2016,7168,8190,2046,0},
    {7182,7998,1008,192,1008,7998,7182,0},
    {30,62,4192,8128,8128,4192,62,30},
    {7694,7942,4482,4290,4194,6206,7198,0},
    {0,0,8190,8190,4098,4098,0,0},
    {6,30,120,480,1920,7680,6144,0},
    {0,0,4098,4098,8190,8190,0,0},
    {8,12,6,3,6,12,8,0},
    {16384,16384,16384,16384,16384,16384,16384,16384},
    {6176,8190,8191,4129,4099,6150,2048,0},
    {3584,7968,4384,4384,4064,8128,4096,0},
    {4098,8190,4094,4128,4192,8128,3968,0},
    {4032,8160,4128,4128,4128,6240,2112,0},
    {3968,8128,4192,4130,4094,8190,4096,0},
    {4032,8160,4384,4384,4384,6624,2496,0},
    {4128,8188,8190,4130,6,12,0,0},
    {20416,57312,36896,36896,65472,32736,32,0},
    {4098,8190,8190,64,32,8160,8128,0},
    {0,0,4128,8166,8166,4096,0,0},
    {0,24576,57344,32768,32800,65510,32742,0},
    {4098,8190,8190,768,1920,7392,6240,0},
    {0,0,4098,8190,8190,4096,0,0},
    {8160,8160,96,8128,96,8160,8128,0},
    {32,8160,8128,32,32,8160,8128,0},
    {4032,8160,4128,4128,4128,8160,4032,0},
    {32800,65504,65472,36896,4128,8160,4032,0},
    {4032,8160,4128,36896,65472,65504,32800,0},
    {4128,8160,8128,4192,32,224,192,0},
    {2112,6368,4512,4384,4896,7776,3136,0},
    {32,32,4092,8190,4128,6176,2048,0},
    {4064,8160,4096,4096,4064,8160,4096,0},
    {0,2016,4064,6144,6144,4064,2016,0},
    {4064,8160,6144,3840,6144,8160,4064,0},
    {6240,7392,1920,768,1920,7392,6240,0},
    {4064,40928,36864,36864,53248,32736,16352,0},
    {6240,7264,5664,4896,4512,6368,6240,0},
    {0,192,192,4092,7998,4098,4098,0},
    {0,0,0,8190,8190,0,0,0},
    {0,4098,4098,7998,4092,192,192,0},
    {4,6,2,6,4,6,2,0},
    {2032,3096,6604,4644,4644,6476,3096,2032}
}

-- text ink state (paper=0, ink=1)
local textInk = {0, 0}

local function textCode(text, i)
    local c = string.byte(text, i)
    if c == 0x01 then  -- paper color
        textInk[1] = string.byte(text, i + 1)
        return 1
    elseif c == 0x02 then  -- ink color
        textInk[2] = string.byte(text, i + 1)
        return 1
    end
    return 0
end

-- Draw small text at pixel position pos
function Video_Write(pos, text)
    local i = 1
    while i <= #text do
        local c = string.byte(text, i)
        if textCode(text, i) ~= 0 then
            i = i + 2
        else
            local idx = c - 32 + 1
            local cs = charSet[idx]
            if cs then
                local width = cs[1]
                for col = 2, width do
                    local pixel = pos
                    local byte = cs[col]
                    for bit = 0, 7 do
                        local v = band(rshift(byte, bit), 1)
                        System_SetPixel(pixel, textInk[v + 1])
                        pixel = pixel + WIDTH
                    end
                    pos = pos + 1
                end
            end
            i = i + 1
        end
    end
end

-- Draw large text (16-row tall) at pixel position pos, starting at x column
function Video_WriteLarge(pos, x, text)
    local i = 1
    while i <= #text do
        local c = string.byte(text, i)
        if textCode(text, i) ~= 0 then
            i = i + 2
        else
            local cs = charSetLarge[c + 1]
            if cs then
                for col = 0, 7 do
                    local cx = x + col
                    if cx >= 0 and cx < WIDTH then
                        local pixel = pos + cx
                        local word = cs[col + 1] or 0
                        for bit = 0, 15 do
                            local v = band(rshift(word, bit), 1)
                            System_SetPixel(pixel, textInk[v + 1])
                            pixel = pixel + WIDTH
                        end
                    end
                end
            end
            x = x + 8
            i = i + 1
        end
    end
end

-- Piano key drawing (for title screen keyboard)
function Video_PianoKey(pos, note, ink)
    local cs = charSetLarge[note + 1]
    if not cs then return end
    for col = 0, 6 do
        local pixel = pos + col
        local word = cs[col + 1] or 0
        for row = 0, 15 do
            if band(rshift(word, row), 1) ~= 0 then
                System_SetPixel(pixel, ink)
            end
            pixel = pixel + WIDTH
        end
    end
end

-- Copy pixel bitmap from byte array (for title screen)
-- src: array of bytes, each bit = 1 pixel
function Video_CopyBytes(src)
    local pixel = 0
    local total = 2048 + 256
    for si = 1, total do
        local byte = src[si] or 0
        for bit = 7, 0, -1 do
            videoPixel[pixel] = band(rshift(byte, bit), 1)
            pixel = pixel + 1
        end
    end
end

-- Apply color attributes to tiles (for title screen)
function Video_CopyColour(src, dest, size)
    for i = 0, size - 1 do
        local b = src[i + 1] or 0
        Video_TilePaper(dest + i, rshift(b, 4))
        Video_TileInk(dest + i, band(b, 0x0f))
    end
end
