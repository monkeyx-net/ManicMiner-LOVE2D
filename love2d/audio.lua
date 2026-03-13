-- audio.lua: square wave synthesis matching the C original

local VOLUME      = 32768 / 4
local MUSICVOLUME = VOLUME / 8
local SFXVOLUME   = VOLUME / 4

local NCHANNELS = 8
local NMUSIC    = 5
local NSFX      = 3

local EV_NOTEOFF = 0x00
local EV_NOTEON  = 0x10
local EV_UNDRAW  = 0x20
local EV_DRAW    = 0x30
local EV_BORDER  = 0x40
local EV_END     = 0x50

-- Frequency table: phase increment for each MIDI note
-- u32 values from C, represent phase delta for 32-bit phase accumulator at SAMPLERATE
local frequencyTable = {
    0x00184cbb, 0x0019bea3, 0x001b4688, 0x001ce5bd, 0x001e9da1, 0x00206fae, 0x00225d71, 0x00246891,
    0x002692cb, 0x0028ddfb, 0x002b4c15, 0x002ddf2d, 0x00309976, 0x00337d46, 0x00368d11, 0x0039cb7a,
    0x003d3b43, 0x0040df5c, 0x0044bae3, 0x0048d122, 0x004d2597, 0x0051bbf7, 0x0056982b, 0x005bbe5b,
    0x006132ed, 0x0066fa8b, 0x006d1a25, 0x007396f4, 0x007a7686, 0x0081beba, 0x008975c6, 0x0091a244,
    0x009a4b30, 0x00a377ee, 0x00ad3056, 0x00b77cb7, 0x00c265db, 0x00cdf516, 0x00da344a, 0x00e72de9,
    0x00f4ed0c, 0x01037d74, 0x0112eb8c, 0x01234488, 0x01349660, 0x0146efdc, 0x015a60ad, 0x016ef96d,
    0x0184cbb6, 0x019bea2e, 0x01b46891, 0x01ce5bd2, 0x01e9da1b, 0x0206fae5, 0x0225d719, 0x02468913,
    0x02692cbe, 0x028ddfb9, 0x02b4c15a, 0x02ddf2dc, 0x0309976d, 0x0337d45a, 0x0368d125, 0x039cb7a5,
    0x03d3b434, 0x040df5cc, 0x044bae33, 0x048d1224, 0x04d2597f, 0x051bbf72, 0x056982b5, 0x05bbe5b7,
    0x06132edb, 0x066fa8b7, 0x06d1a249, 0x07396f4b, 0x07a76867, 0x081beb9b, 0x08975c67, 0x091a2448,
    0x09a4b300, 0x0a377ee5, 0x0ad3056f, 0x0b77cb68, 0x0c265db7, 0x0cdf5173, 0x0da3448d, 0x0e72de96,
    0x0f4ed0d9, 0x1037d72a, 0x112eb8ce, 0x1234489d, 0x134965f4, 0x146efdcb, 0x15a60ac1, 0x16ef96f1,
    0x184cbb6f, 0x19bea2c3, 0x1b468941, 0x1ce5bd2c, 0x1e9da187, 0x206fae82, 0x225d719d, 0x24689107,
    0x2692cc1e, 0x28ddfb96, 0x2b4c1582, 0x2ddf2de3, 0x309976df, 0x337d4586, 0x368d1283, 0x39cb7a58,
    0x3d3b430f, 0x40df5d05, 0x44bae33a, 0x48d1220f, 0x4d25983c, 0x51bbf72d, 0x56982bf5, 0x5bbe5ac8,
    0x6132edbe, 0x66fa8c2a, 0x6d1a23d8, 0x7396f4b1, 0x7a768772, 0x81beb8a3, 0x8975c674, 0x91a245b2
}

-- Pan table (256 entries: 256..0)
local panTable = {
    256,255,254,253,251,250,249,248,247,246,245,243,242,241,240,
    239,238,237,235,234,233,232,231,230,229,227,226,225,224,
    223,222,221,219,218,217,216,215,214,213,211,210,209,208,
    207,206,205,203,202,201,200,199,198,197,195,194,193,192,
    191,190,189,187,186,185,184,183,182,181,179,178,177,176,
    175,174,173,171,170,169,168,167,166,165,163,162,161,160,
    159,158,157,155,154,153,152,151,150,149,147,146,145,144,
    143,142,141,139,138,137,136,135,134,133,131,130,129,128,
    127,126,125,123,122,121,120,119,118,117,115,114,113,112,
    111,110,109,107,106,105,104,103,102,101, 99, 98, 97, 96,
     95, 94, 93, 91, 90, 89, 88, 87, 86, 85, 83, 82, 81, 80,
     79, 78, 77, 75, 74, 73, 72, 71, 70, 69, 67, 66, 65, 64,
     63, 62, 61, 59, 58, 57, 56, 55, 54, 53, 51, 50, 49, 48,
     47, 46, 45, 43, 42, 41, 40, 39, 38, 37, 35, 34, 33, 32,
     31, 30, 29, 27, 26, 25, 24, 23, 22, 21, 19, 18, 17, 16,
     15, 14, 13, 11, 10,  9,  8,  7,  6,  5,  3,  2,  1,  0
}

-- SFX pitch sequences (0-terminated, 1-indexed in Lua)
local sfxPitch = {
    -- SFX_DIE (0)
    {84,81,78,75,72,69,66,63,60,57,54,51,48,45,42,39,0},
    -- SFX_KONG (1)
    {84,83,82,81,80,79,78,77,76,75,74,73,72,71,70,69,68,67,66,65,64,63,62,61,60,0},
    -- SFX_GAMEOVER (2)
    {36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,0},
    -- SFX_AIR (3) - long sequence
    (function()
        local t = {}
        local v = 88
        for i = 0, 27 do
            for j = 0, 7 do
                t[#t+1] = v
            end
            v = v - 1
        end
        t[#t+1] = 0
        return t
    end)(),
    -- SFX_VICTORY (4)
    {36,42,48,54,60,66,72,78,84,0},
    -- SFX_NONE (5)
    {0}
}

-- Audio channel state
local function newChannel(lv, rv)
    return {
        left  = {lv or 0, -(lv or 0), 0},
        right = {rv or 0, -(rv or 0), 0},
        phase = 0,
        frequency = 0,
        active = false   -- false = DoNothing, true = DoPhase
    }
end

local audioChannel = {}
for i = 1, 3 do
    audioChannel[i] = newChannel(0, 0)
end
for i = 4, 8 do
    audioChannel[i] = newChannel(MUSICVOLUME, MUSICVOLUME)
end

local musicChannel = {
    audioChannel[4], audioChannel[5], audioChannel[6],
    audioChannel[7], audioChannel[8]
}

-- SFX channel info
local function newSfx(ch)
    return {
        pitch    = sfxPitch[SFX_NONE + 1],
        pitchIdx = 1,
        data     = 0,
        length   = 1,
        channel  = ch,
        clock    = 0,
        state    = "off",    -- "off", "on", "play", "air", "victory", "miner"
        doPlay   = "play",
    }
end

local sfxInfo = {
    newSfx(audioChannel[1]),
    newSfx(audioChannel[2]),
    newSfx(audioChannel[3]),
}

-- Music state
local musicScore = {}  -- loaded below
local musicIndex = 1   -- 1=title, 2=game (1-based)
local musicCursor = 1
local musicDelta  = 0
local musicClock  = 0

local musicChannelsCount = 0  -- 0=sfx only, NCHANNELS=full
local sfxClock = 0

audioMusicPlaying = MUS_STOP

-- Piano key draw queue (for title screen animation)
local drawQueue = {}

-- Key position table (for piano keys, indexed by note number 0..95)
local keyPos = {
    -- 0..35: offscreen/unused
    {t=0,pos=0},{t=1,pos=0},{t=0,pos=0},{t=1,pos=0},{t=0,pos=0},
    {t=0,pos=0},{t=1,pos=0},{t=0,pos=0},{t=1,pos=0},{t=0,pos=0},{t=1,pos=0},{t=0,pos=0},
    {t=0,pos=0},{t=1,pos=0},{t=0,pos=0},{t=1,pos=0},{t=0,pos=0},
    {t=0,pos=0},{t=1,pos=0},{t=0,pos=0},{t=1,pos=0},{t=0,pos=0},{t=1,pos=0},{t=0,pos=0},
    {t=0,pos=0},{t=1,pos=0},{t=0,pos=0},{t=1,pos=0},{t=0,pos=0},
    {t=0,pos=0},{t=1,pos=0},{t=0,pos=0},{t=1,pos=0},{t=0,pos=0},{t=1,pos=0},{t=0,pos=0},
    -- 36..47
    {t=0,pos=4},{t=1,pos=8},{t=0,pos=12},{t=1,pos=16},{t=0,pos=20},
    {t=0,pos=28},{t=1,pos=32},{t=0,pos=36},{t=1,pos=40},{t=0,pos=44},{t=1,pos=48},{t=0,pos=52},
    -- 48..59
    {t=0,pos=60},{t=1,pos=64},{t=0,pos=68},{t=1,pos=72},{t=0,pos=76},
    {t=0,pos=84},{t=1,pos=88},{t=0,pos=92},{t=1,pos=96},{t=0,pos=100},{t=1,pos=104},{t=0,pos=108},
    -- 60..71
    {t=0,pos=116},{t=1,pos=120},{t=0,pos=124},{t=1,pos=128},{t=0,pos=132},
    {t=0,pos=140},{t=1,pos=144},{t=0,pos=148},{t=1,pos=152},{t=0,pos=156},{t=1,pos=160},{t=0,pos=164},
    -- 72..83
    {t=0,pos=172},{t=1,pos=176},{t=0,pos=180},{t=1,pos=184},{t=0,pos=188},
    {t=0,pos=196},{t=1,pos=200},{t=0,pos=204},{t=1,pos=208},{t=0,pos=212},{t=1,pos=216},{t=0,pos=220},
    -- 84..95
    {t=0,pos=228},{t=1,pos=232},{t=0,pos=236},{t=1,pos=240},{t=0,pos=244},
    {t=0,pos=252},{t=1,pos=0},{t=0,pos=0},{t=1,pos=0},{t=0,pos=0},{t=1,pos=0},{t=0,pos=0}
}

local noteTypes = {26,25,27,25,28,26,25,27,25,27,25,28}  -- 12-note pattern for key shape
local keyColors = {0x7, 0x0, 0x5, 0x2}  -- white/black/highlight/active colors

local function DrawListAdd(note, state)
    if note < 0 or note >= #keyPos then return end
    local kp = keyPos[note + 1]
    local ntype = noteTypes[note % 12 + 1]
    local attr  = keyColors[bor(state, kp.t) + 1]
    table.insert(drawQueue, {pos = KEYBOARD + kp.pos, noteType = ntype, attr = attr})
end

function Audio_Drawer()
    for _, entry in ipairs(drawQueue) do
        Video_PianoKey(entry.pos, entry.noteType, entry.attr)
    end
    drawQueue = {}
end

-- Channel helper functions
local function channelStereo(ch, left, right)
    left  = math.floor(SFXVOLUME * left  / 256)
    right = math.floor(SFXVOLUME * right / 256)
    ch.left[1]  =  left;  ch.left[2]  = -left
    ch.right[1] =  right; ch.right[2] = -right
end

local function channelPan(ch, pan)
    pan = math.max(0, math.min(#panTable - 1, pan))
    channelStereo(ch, panTable[pan + 1], 256 - panTable[pan + 1])
end

-- Generate one audio sample pair (left, right)
-- Called SAMPLERATE times per second
local function channelOutput(ch)
    if not ch.active then
        ch.left[3] = 0; ch.right[3] = 0
        return
    end
    -- 32-bit phase accumulator, top bit determines square wave state
    ch.phase = band(ch.phase + ch.frequency, 0xFFFFFFFF)
    local idx = band(rshift(ch.phase, 31), 1) + 1
    ch.left[3]  = ch.left[idx]
    ch.right[3] = ch.right[idx]
end

-- Love2D QueueableSource for audio output
local audioSource = nil
local audioBufSize = 512  -- samples per buffer (~23ms at 22050 Hz)

function Audio_Init()
    audioSource = love.audio.newQueueableSource(SAMPLERATE, 16, 2, 4)
    audioSource:play()
end

-- Audio timer for game sync
local audioGameTimer = nil
local audioSampleCounter = 0
local samplesPerTick = SAMPLERATE / TICKRATE  -- ~367.5

-- Called once per game frame to produce audio and trigger events
function Audio_Update(dt)
    if not audioSource then return end

    -- Generate enough audio to keep the queue full
    local buffered = audioSource:getFreeBufferCount()
    -- Each buffer covers ~1/8 second
    for b = 1, buffered do
        -- Tick music/sfx events once per ~audioSampleCounter cycle
        local buf = love.sound.newSoundData(audioBufSize, SAMPLERATE, 16, 2)
        for i = 0, audioBufSize - 1 do
            audioSampleCounter = audioSampleCounter + 1
            if audioSampleCounter >= samplesPerTick then
                audioSampleCounter = audioSampleCounter - samplesPerTick
                Audio_MusicEvent()
                Audio_SfxEvent()
            end

            local L = 0
            local R = 0
            for c = 1, musicChannelsCount do
                channelOutput(audioChannel[c])
                L = L + audioChannel[c].left[3]
                R = R + audioChannel[c].right[3]
            end
            L = math.max(-32768, math.min(32767, L))
            R = math.max(-32768, math.min(32767, R))
            buf:setSample(i * 2,     L / 32768)
            buf:setSample(i * 2 + 1, R / 32768)
        end
        audioSource:queue(buf)
    end
    if not audioSource:isPlaying() then
        audioSource:play()
    end
end

-- SFX helpers
local function sfxOff(sfx)
    sfx.state = "off"
    sfx.channel.active = false
    sfx.channel.left[3] = 0
    sfx.channel.right[3] = 0
end

local function sfxPlay(sfx)
    sfx.channel.frequency = frequencyTable[sfx.pitch[sfx.pitchIdx] + 1] or 0
    sfx.clock = sfx.clock + sfx.length
    sfx.pitchIdx = sfx.pitchIdx + 1
    if sfx.pitch[sfx.pitchIdx] == nil or sfx.pitch[sfx.pitchIdx] == 0 then
        sfxOff(sfx)
    end
end

local function sfxAir(sfx)
    channelPan(sfx.channel, sfx.data)
    sfxPlay(sfx)
    sfx.data = sfx.data - 1
end

local function sfxVictory(sfx)
    sfxPlay(sfx)
    if sfx.pitch[sfx.pitchIdx] == nil or sfx.pitch[sfx.pitchIdx] == 0 then
        sfx.data = sfx.data - 1
        if sfx.data > 0 then
            sfx.pitchIdx = 1
            sfx.pitch = sfxPitch[SFX_VICTORY + 1]
            sfx.state = "victory"
        end
    end
end

local function sfxMiner(sfx)
    sfx.channel.active = true       -- activate channel
    sfx.clock = sfx.clock + sfx.length  -- schedule turn-off
    sfx.state = "mineroff"          -- next clock fire = turn off
end

local function sfxMinerOff(sfx)
    sfxOff(sfx)
end

function Audio_MinerSfx(note, length)
    local sfx = sfxInfo[1]
    sfx.channel.frequency = frequencyTable[note + 1] or 0
    sfx.clock = sfxClock
    channelPan(sfx.channel, minerX - 8)
    sfx.length = length
    sfx.state = "miner"
    sfx.channel.active = true
end

function Audio_Sfx(sfx_id)
    if sfx_id ~= SFX_KONG then
        sfxOff(sfxInfo[1])
        sfxOff(sfxInfo[2])
        local sfx = sfxInfo[3]
        sfx.clock = sfxClock
        if sfx_id == SFX_AIR then
            sfx.length = 1
            sfx.pitch = sfxPitch[SFX_AIR + 1]
            sfx.pitchIdx = math.max(1, 225 - (gameAirOld or 224))
            sfx.data = gameAirOld or 224
            sfx.state = "air"
        elseif sfx_id == SFX_VICTORY then
            sfx.length = 1
            sfx.pitch = sfxPitch[SFX_VICTORY + 1]
            sfx.pitchIdx = 1
            sfx.data = 50
            channelStereo(sfx.channel, 256, -256)
            sfx.state = "victory"
        elseif sfx_id == SFX_DIE then
            sfx.length = 1
            sfx.pitch = sfxPitch[SFX_DIE + 1]
            sfx.pitchIdx = 1
            channelPan(sfx.channel, (minerX or 128) - 8)
            sfx.state = "play"
        elseif sfx_id == SFX_GAMEOVER then
            sfx.length = 2
            sfx.pitch = sfxPitch[SFX_GAMEOVER + 1]
            sfx.pitchIdx = 1
            channelStereo(sfx.channel, 256, -256)
            sfx.state = "play"
        end
        sfx.channel.active = true
        sfx.channel.frequency = frequencyTable[sfx.pitch[sfx.pitchIdx] + 1] or 0
    else
        local sfx = sfxInfo[2]
        sfx.length = 5
        sfx.pitch = sfxPitch[SFX_KONG + 1]
        sfx.pitchIdx = 1
        channelPan(sfx.channel, 112)
        sfx.state = "play"
        sfx.clock = sfxClock
        sfx.channel.active = true
        sfx.channel.frequency = frequencyTable[sfx.pitch[sfx.pitchIdx] + 1] or 0
    end
end

-- Music score data (same as C, but 1-indexed arrays)
-- Two scores: [1]=title (MUS_TITLE=0+1), [2]=game (MUS_GAME=1+1)
-- Stored as flat byte arrays matching the C musicScore arrays
musicScore[1] = {  -- Title music
    0x40,48,57,12,32,57,2,
    0x4c,48,61,12,32,61,2,
    0x46,48,64,12,32,64,2,
    0x46,48,45,0,52,64,12,32,45,0,36,64,2,
    0x47,48,49,0,49,52,12,32,49,0,33,52,2,
    0x4a,48,49,0,49,52,0,51,73,0,52,76,12,32,49,0,33,52,0,35,73,0,36,76,2,
    0x4a,48,45,0,51,73,0,52,76,12,32,45,0,35,73,0,36,76,2,
    0x47,48,49,0,49,52,12,32,49,0,33,52,2,
    0x40,48,49,0,49,52,0,51,69,0,52,73,12,32,49,0,33,52,0,35,69,0,36,73,2,
    0x40,48,45,0,51,69,0,52,73,12,32,45,0,35,69,0,36,73,2,
    0x47,48,49,0,49,52,12,32,49,0,33,52,2,
    0x40,48,49,0,49,52,0,52,57,12,32,49,0,33,52,0,36,57,2,
    0x40,48,45,0,52,57,12,32,45,0,36,57,2,
    0x4c,48,49,0,49,52,0,52,61,12,32,49,0,33,52,0,36,61,2,
    0x46,48,49,0,49,52,0,52,64,12,32,49,0,33,52,0,36,64,2,
    0x46,48,47,0,51,62,0,52,64,12,32,47,0,35,62,0,36,64,2,
    0x40,48,50,0,49,52,12,32,50,0,33,52,2,
    0x4a,48,50,0,49,52,0,51,74,0,52,76,12,32,50,0,33,52,0,35,74,0,36,76,2,
    0x4a,48,47,0,51,74,0,52,76,12,32,47,0,35,74,0,36,76,2,
    0x40,48,50,0,49,52,12,32,50,0,33,52,2,
    0x40,48,50,0,49,52,0,51,68,0,52,74,12,32,50,0,33,52,0,35,68,0,36,74,2,
    0x40,48,47,0,51,68,0,52,74,12,32,47,0,35,68,0,36,74,2,
    0x40,48,50,0,49,52,12,32,50,0,33,52,2,
    0x47,48,50,0,49,52,0,52,56,12,32,50,0,33,52,0,36,56,2,
    0x47,48,47,0,52,56,12,32,47,0,36,56,2,
    0x4a,48,50,0,49,52,0,52,59,12,32,50,0,33,52,0,36,59,2,
    0x47,48,50,0,49,52,0,52,66,12,32,50,0,33,52,0,36,66,2,
    0x47,48,44,0,52,66,12,32,44,0,36,66,2,
    0x40,48,50,0,49,52,12,32,50,0,33,52,2,
    0x4a,48,50,0,49,52,0,51,74,0,52,78,12,32,50,0,33,52,0,35,74,0,36,78,2,
    0x4a,48,40,0,51,74,0,52,78,12,32,40,0,35,74,0,36,78,2,
    0x40,48,50,0,49,52,12,32,50,0,33,52,2,
    0x40,48,50,0,49,52,0,51,68,0,52,74,12,32,50,0,33,52,0,35,68,0,36,74,2,
    0x40,48,44,0,51,68,0,52,74,12,32,44,0,35,68,0,36,74,2,
    0x40,48,50,0,49,52,12,32,50,0,33,52,2,
    0x47,48,50,0,49,52,0,52,56,12,32,50,0,33,52,0,36,56,2,
    0x47,48,40,0,52,56,12,32,40,0,36,56,2,
    0x4a,48,50,0,49,52,0,52,59,12,32,50,0,33,52,0,36,59,2,
    0x47,48,50,0,49,52,0,52,66,12,32,50,0,33,52,0,36,66,2,
    0x47,48,45,0,52,66,12,32,45,0,36,66,2,
    0x47,48,49,0,49,52,12,32,49,0,33,52,2,
    0x4a,48,49,0,49,52,0,51,73,0,52,78,12,32,49,0,33,52,0,35,73,0,36,78,2,
    0x4a,48,40,0,51,73,0,52,78,12,32,40,0,35,73,0,36,78,2,
    0x47,48,49,0,49,52,12,32,49,0,33,52,2,
    0x40,48,49,0,49,52,0,51,69,0,52,73,12,32,49,0,33,52,0,35,69,0,36,73,2,
    0x40,48,45,0,51,69,0,52,73,12,32,45,0,35,69,0,36,73,2,
    0x47,48,49,0,49,52,12,32,49,0,33,52,2,
    0x40,48,49,0,49,52,0,52,57,12,32,49,0,33,52,0,36,57,2,
    0x40,48,45,0,52,57,12,32,45,0,36,57,2,
    0x4c,48,49,0,49,52,0,52,61,12,32,49,0,33,52,0,36,61,2,
    0x46,48,49,0,49,52,0,52,64,12,32,49,0,33,52,0,36,64,2,
    0x40,48,49,0,52,69,12,32,49,0,36,69,2,
    0x43,48,52,0,49,57,12,32,52,0,33,57,2,
    0x43,48,52,0,49,57,0,51,76,0,52,81,12,32,52,0,33,57,0,35,76,0,36,81,2,
    0x43,48,49,0,51,76,0,52,81,12,32,49,0,35,76,0,36,81,2,
    0x43,48,52,0,49,57,12,32,52,0,33,57,2,
    0x4a,48,52,0,49,57,0,51,73,0,52,76,12,32,52,0,33,57,0,35,73,0,36,76,2,
    0x4a,48,49,0,51,73,0,52,76,12,32,49,0,35,73,0,36,76,2,
    0x43,48,52,0,49,57,12,32,52,0,33,57,2,
    0x40,48,52,0,52,57,12,32,52,0,36,57,2,
    0x40,48,49,0,52,57,12,32,49,0,36,57,2,
    0x4c,48,52,0,49,57,0,52,61,12,32,52,0,33,57,0,36,61,2,
    0x46,48,52,0,49,57,0,52,64,12,32,52,0,33,57,0,36,64,2,
    0x40,48,50,0,52,69,12,32,50,0,36,69,2,
    0x45,48,54,0,49,57,0,50,59,12,32,54,0,33,57,0,34,59,2,
    0x4c,48,54,0,49,57,0,50,59,0,51,78,0,52,81,12,32,54,0,33,57,0,34,59,0,35,78,0,36,81,2,
    0x4c,48,50,0,51,78,0,52,81,12,32,50,0,35,78,0,36,81,2,
    0x45,48,54,0,49,57,0,50,59,12,32,54,0,33,57,0,34,59,2,
    0x4a,48,54,0,49,57,0,50,59,0,51,74,0,52,78,12,32,54,0,33,57,0,34,59,0,35,74,0,36,78,2,
    0x4a,48,50,0,51,74,0,52,78,12,32,50,0,35,74,0,36,78,2,
    0x40,48,54,0,49,57,0,50,59,12,32,54,0,33,57,0,34,59,2,
    0x4a,48,59,12,32,59,2,
    0x4a,48,59,12,32,59,2,
    0x4c,48,62,12,32,62,2,
    0x47,48,66,12,32,66,2,
    0x45,48,44,0,52,66,12,32,44,2,
    0x47,48,50,0,49,52,12,32,50,0,33,52,2,
    0x47,48,50,0,49,52,12,32,50,0,33,52,0,36,66,2,
    0x45,48,40,0,52,66,12,32,40,0,36,66,2,
    0x45,48,50,0,49,52,0,52,63,12,32,50,0,33,52,0,36,63,2,
    0x46,48,50,0,49,52,0,52,64,12,32,50,0,33,52,0,36,64,2,
    0x47,48,45,0,51,69,0,52,73,12,32,45,2,
    0x4a,48,49,0,49,52,12,32,49,0,33,52,2,
    0x4a,48,49,0,49,52,12,32,49,0,33,52,0,35,69,0,36,73,2,
    0x47,48,40,0,51,69,0,52,73,12,32,40,0,35,69,0,36,73,2,
    0x40,48,49,0,49,52,0,52,69,12,32,49,0,33,52,0,36,69,2,
    0x4c,48,49,0,49,52,0,52,61,12,32,49,0,33,52,0,36,61,2,
    0x4c,48,45,0,49,50,0,50,54,0,52,61,26,36,61,2,
    0x4a,52,59,12,32,45,0,33,50,0,34,54,0,36,59,2,
    0x47,48,44,0,49,50,0,50,52,0,52,66,26,36,66,2,
    0x46,52,64,12,32,44,0,33,50,0,34,52,0,36,64,2,
    0x47,48,45,0,49,49,0,50,52,0,52,57,12,32,45,0,33,49,0,34,52,0,36,57,16,
    0x40,32,45,2,
    0x40,48,45,0,49,49,0,50,52,0,51,57,0,52,69,12,32,45,0,33,49,0,34,52,0,35,57,0,36,69,2,
    0x47,48,45,0,49,49,0,50,52,0,51,57,0,52,69,12,32,45,0,33,49,0,34,52,0,35,57,0,36,69,30,
    EV_END, MUS_STOP
}

musicScore[2] = {  -- Game music (in-game)
    16,40,0,17,52,11,1,1,17,54,11,0,0,1,1,
    16,47,0,17,55,11,1,1,17,57,11,0,0,1,1,
    16,40,0,17,59,11,1,1,17,55,11,0,0,1,1,
    16,47,0,17,59,23,0,0,1,1,
    16,40,0,17,58,11,1,1,17,54,11,0,0,1,1,
    16,47,0,17,58,23,0,0,1,1,
    16,40,0,17,57,11,1,1,17,53,11,0,0,1,1,
    16,47,0,17,57,23,0,0,1,1,
    16,40,0,17,52,11,1,1,17,54,11,0,0,1,1,
    16,47,0,17,55,11,1,1,17,57,11,0,0,1,1,
    16,40,0,17,59,11,1,1,17,55,11,0,0,1,1,
    16,47,0,17,59,11,1,1,17,64,11,0,0,1,1,
    16,43,0,17,62,11,1,1,17,59,11,0,0,1,1,
    16,50,0,17,55,11,1,1,17,59,11,0,0,1,1,
    16,43,0,17,62,23,0,1,16,50,23,0,0,1,1,
    16,40,0,17,52,11,1,1,17,54,11,0,0,1,1,
    16,47,0,17,55,11,1,1,17,57,11,0,0,1,1,
    16,40,0,17,59,11,1,1,17,55,11,0,0,1,1,
    16,47,0,17,59,23,0,0,1,1,
    16,40,0,17,58,11,1,1,17,54,11,0,0,1,1,
    16,47,0,17,58,23,0,0,1,1,
    16,40,0,17,57,11,1,1,17,53,11,0,0,1,1,
    16,47,0,17,57,23,0,0,1,1,
    16,40,0,17,52,11,1,1,17,54,11,0,0,1,1,
    16,47,0,17,55,11,1,1,17,57,11,0,0,1,1,
    16,40,0,17,59,11,1,1,17,55,11,0,0,1,1,
    16,47,0,17,59,11,1,1,17,64,11,0,0,1,1,
    16,43,0,17,62,11,1,1,17,59,11,0,0,1,1,
    16,50,0,17,55,11,1,1,17,59,11,0,0,1,1,
    16,43,0,17,62,23,0,1,16,50,23,0,0,1,1,
    16,47,0,17,59,11,1,1,17,61,11,0,0,1,1,
    16,54,0,17,63,11,1,1,17,64,11,0,0,1,1,
    16,47,0,17,66,11,1,1,17,63,11,0,0,1,1,
    16,54,0,17,66,23,0,0,1,1,
    16,43,0,17,67,11,1,1,17,63,11,0,0,1,1,
    16,51,0,17,67,23,0,0,1,1,
    16,47,0,17,66,11,1,1,17,63,11,0,0,1,1,
    16,50,0,17,66,23,0,0,1,1,
    16,47,0,17,59,11,1,1,17,61,11,0,0,1,1,
    16,54,0,17,63,11,1,1,17,64,11,0,0,1,1,
    16,47,0,17,66,11,1,1,17,63,11,0,0,1,1,
    16,54,0,17,66,23,0,0,1,1,
    16,43,0,17,67,11,1,1,17,63,11,0,0,1,1,
    16,51,0,17,67,23,0,0,1,1,
    16,47,0,17,66,23,0,1,16,50,23,0,0,1,1,
    16,47,0,17,59,11,1,1,17,61,11,0,0,1,1,
    16,54,0,17,63,11,1,1,17,64,11,0,0,1,1,
    16,47,0,17,66,11,1,1,17,63,11,0,0,1,1,
    16,54,0,17,66,23,0,0,1,1,
    16,43,0,17,67,11,1,1,17,63,11,0,0,1,1,
    16,51,0,17,67,23,0,0,1,1,
    16,47,0,17,66,11,1,1,17,63,11,0,0,1,1,
    16,50,0,17,66,23,0,0,1,1,
    16,47,0,17,59,11,1,1,17,61,11,0,0,1,1,
    16,54,0,17,63,11,1,1,17,64,11,0,0,1,1,
    16,47,0,17,66,11,1,1,17,63,11,0,0,1,1,
    16,54,0,17,66,23,0,0,1,1,
    16,43,0,17,67,11,1,1,17,63,11,0,0,1,1,
    16,51,0,17,67,23,0,0,1,1,
    16,47,0,17,66,23,0,1,16,50,23,0,0,1,1,
    16,40,0,17,64,11,1,1,17,66,11,0,0,1,1,
    16,47,0,17,67,11,1,1,17,69,11,0,0,1,1,
    16,40,0,17,71,11,1,1,17,67,11,0,0,1,1,
    16,47,0,17,71,23,0,0,1,1,
    16,40,0,17,70,11,1,1,17,66,11,0,0,1,1,
    16,47,0,17,70,23,0,0,1,1,
    16,40,0,17,69,11,1,1,17,65,11,0,0,1,1,
    16,47,0,17,69,23,0,0,1,1,
    16,40,0,17,64,11,1,1,17,66,11,0,0,1,1,
    16,47,0,17,67,11,1,1,17,69,11,0,0,1,1,
    16,40,0,17,71,11,1,1,17,67,11,0,0,1,1,
    16,47,0,17,71,11,1,1,17,76,11,0,0,1,1,
    16,43,0,17,74,11,1,1,17,71,11,0,0,1,1,
    16,50,0,17,67,11,1,1,17,71,11,0,0,1,1,
    16,43,0,17,74,47,0,0,1,1,
    EV_END, MUS_PLAY
}

-- Music playback state
local curMusicScore = nil
local curMusicIdx = 1

local function MusicReset()
    for i = 1, NMUSIC do
        musicChannel[i].active = false
        musicChannel[i].left[3] = 0
        musicChannel[i].right[3] = 0
    end
    curMusicScore = musicScore[musicIndex]
    curMusicIdx = 1
    musicDelta = 0
    musicClock = 0
end

function Audio_MusicEvent()
    if audioMusicPlaying == MUS_STOP then return end
    if musicDelta ~= musicClock then
        musicClock = musicClock + 1
        return
    end

    repeat
        local event = curMusicScore[curMusicIdx]
        if event == nil then break end
        curMusicIdx = curMusicIdx + 1
        local data = band(event, 0x0f)
        local kind = band(event, 0xf0)
        local time = 0

        if kind == EV_BORDER then
            System_Border(data)
            -- time stays 0, continue
        elseif kind == EV_DRAW then
            DrawListAdd(curMusicScore[curMusicIdx], 2)
            -- FALLTHRU to NOTEON
            musicChannel[data + 1].frequency = frequencyTable[(curMusicScore[curMusicIdx] or 0) + 1] or 0
            musicChannel[data + 1].active = true
            curMusicIdx = curMusicIdx + 1
            time = curMusicScore[curMusicIdx] or 0
            curMusicIdx = curMusicIdx + 1
            musicDelta = musicDelta + time
        elseif kind == EV_NOTEON then
            musicChannel[data + 1].frequency = frequencyTable[(curMusicScore[curMusicIdx] or 0) + 1] or 0
            musicChannel[data + 1].active = true
            curMusicIdx = curMusicIdx + 1
            time = curMusicScore[curMusicIdx] or 0
            curMusicIdx = curMusicIdx + 1
            musicDelta = musicDelta + time
        elseif kind == EV_UNDRAW then
            DrawListAdd(curMusicScore[curMusicIdx], 0)
            curMusicIdx = curMusicIdx + 1
            musicChannel[data + 1].active = false
            musicChannel[data + 1].left[3] = 0
            musicChannel[data + 1].right[3] = 0
            time = curMusicScore[curMusicIdx] or 0
            curMusicIdx = curMusicIdx + 1
            musicDelta = musicDelta + time
        elseif kind == EV_NOTEOFF then
            musicChannel[data + 1].active = false
            musicChannel[data + 1].left[3] = 0
            musicChannel[data + 1].right[3] = 0
            time = curMusicScore[curMusicIdx] or 0
            curMusicIdx = curMusicIdx + 1
            musicDelta = musicDelta + time
        elseif kind == EV_END then
            -- data byte is next playing state
            audioMusicPlaying = curMusicScore[curMusicIdx] or MUS_STOP
            curMusicIdx = curMusicIdx + 1
            MusicReset()
            time = audioMusicPlaying ~= 0 and 0 or 1
        else
            time = 1  -- unknown, just advance
        end

        if time ~= 0 then break end
    until false

    musicClock = musicClock + 1
end

function Audio_SfxEvent()
    for i = 1, NSFX do
        local sfx = sfxInfo[i]
        if sfx.clock == sfxClock then
            local st = sfx.state
            if st == "play" then
                sfxPlay(sfx)
            elseif st == "air" then
                sfxAir(sfx)
            elseif st == "victory" then
                sfxVictory(sfx)
            elseif st == "miner" then
                sfxMiner(sfx)
            elseif st == "mineroff" then
                sfxMinerOff(sfx)
            end
        end
    end
    sfxClock = sfxClock + 1
end

function Audio_Play(playing)
    audioMusicPlaying = playing
    if playing == MUS_PLAY then
        musicChannelsCount = NCHANNELS
    else
        musicChannelsCount = NSFX
    end
end

function Audio_Music(music, playing)
    musicIndex = music + 1  -- 1-based
    MusicReset()
    for i = 1, NSFX do sfxOff(sfxInfo[i]) end
    Audio_Play(playing)
    drawQueue = {}
end

function Audio_Shutdown()
    if audioSource then
        audioSource:stop()
        audioSource = nil
    end
end
