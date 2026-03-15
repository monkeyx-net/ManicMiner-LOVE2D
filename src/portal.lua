-- portal.lua: Level exit portal logic

local portalData = {
    -- level 0
    {x=29, y=13, gfx={65535,37449,46811,65535,37449,46811,65535,37449,46811,65535,37449,46811,65535,37449,46811,65535}, colour={0x7,0x5}},
    -- level 1
    {x=29, y=13, gfx={65535,37449,37449,37449,37449,37449,37449,37449,37449,37449,37449,37449,37449,37449,37449,65535}, colour={0x4,0xf}},
    -- level 2
    {x=29, y=11, gfx={65535,33861,39321,41505,41505,39321,33861,33861,39321,41505,41505,39321,33861,33861,39321,65535}, colour={0xa,0xe}},
    -- level 3
    {x=29, y=1,  gfx={61166,30583,48059,56797,61166,30583,48059,56797,61166,30583,48059,56797,61166,30583,48059,56797}, colour={0xa,0xc}},
    -- level 4
    {x=15, y=13, gfx={65535,37449,37449,37449,37449,37449,37449,37449,37449,37449,37449,37449,37449,37449,37449,65535}, colour={0x1,0x0}},
    -- level 5
    {x=29, y=0,  gfx={65535,33153,49149,49149,45069,45069,45069,61455,61455,45069,45069,45069,49149,49149,33153,65535}, colour={0x1,0xa}},
    -- level 6
    {x=15, y=13, gfx={65535,33153,33153,33153,33153,33153,33153,65535,65535,33153,33153,33153,33153,33153,33153,65535}, colour={0xe,0xf}},
    -- level 7
    {x=15, y=13, gfx={65535,32769,49155,40965,36873,51219,42021,37449,51603,42021,37449,51603,42021,51603,37449,65535}, colour={0x1,0x6}},
    -- level 8
    {x=1,  y=0,  gfx={65535,32769,33153,33345,33825,34833,36873,41349,41349,36873,34833,33825,33345,33153,32769,65535}, colour={0xc,0xf}},
    -- level 9
    {x=12, y=13, gfx={65535,63631,34961,43665,43669,35461,37009,54713,54613,53573,35129,35075,43179,43691,35465,65535}, colour={0x1,0x5}},
    -- level 10
    {x=1,  y=1,  gfx={65535,55979,60011,65535,36873,36873,65535,36873,36873,65535,36873,36873,65535,36873,36873,65535}, colour={0xe,0xc}},
    -- level 11
    {x=15, y=13, gfx={65535,32769,36849,36849,36849,36849,36849,35889,35889,36849,36849,36849,36849,36849,32769,65535}, colour={0x8,0xa}},
    -- level 12
    {x=1,  y=13, gfx={960,2016,4080,2448,2448,2016,1440,576,24966,63519,65151,1504,1952,65151,63519,24582}, colour={0x1,0x7}},
    -- level 13
    {x=15, y=0,  gfx={65535,65535,64575,63519,61455,57351,49539,49731,49731,49539,57351,61455,63519,64575,65535,65535}, colour={0x9,0x6}},
    -- level 14
    {x=1,  y=3,  gfx={65535,32769,32769,32769,32769,34817,43521,39997,65351,39937,43521,34817,32769,32769,32769,65535}, colour={0x6,0x5}},
    -- level 15
    {x=12, y=5,  gfx={65535,33153,33153,65535,33153,33153,65535,33153,33153,65535,33153,33153,65535,33153,33153,65535}, colour={0xc,0x2}},
    -- level 16
    {x=29, y=1,  gfx={65535,32769,49149,40965,42405,42405,42405,42405,42405,42405,45045,42405,42405,42405,42405,65535}, colour={0x6,0x2}},
    -- level 17
    {x=29, y=0,  gfx={65535,32769,45069,40965,43605,43605,43605,43605,43605,43605,43605,43605,40965,45069,32769,65535}, colour={0x8,0xd}},
    -- level 18
    {x=1,  y=1,  gfx={65535,32769,49149,40965,45045,43029,43989,43605,43605,43989,43029,45045,40965,49149,32769,65535}, colour={0x5,0x6}},
    -- level 19
    {x=19, y=5,  gfx={65535,63519,57351,49155,50115,34785,34785,34785,50115,49539,57735,45453,33153,33153,33153,65535}, colour={0xf,0xc}},
}

local portalThis   -- current level's portal data
local portalTile   -- tile index of portal
local portalPos    -- pixel position of portal
local portalFlash  -- 0 or 1 (flashing colour index)
local portalIsReady

local function DoPortalTicker()
    portalFlash = bxor(portalFlash, 1)
end

Portal_Ticker = DoNothing  -- global, swapped to DoPortalTicker when ready

function Portal_Ready()
    Portal_Ticker = DoPortalTicker
    portalIsReady = 1
end

function Portal_Drawer()
    local c = portalThis.colour
    Video_Sprite(portalPos, portalThis.gfx, c[portalFlash + 1], c[bxor(portalFlash, 1) + 1])

    if portalIsReady == 0 or portalTile ~= minerTile then
        return
    end

    if gameLevel == TWENTY and cheatEnabled == 0 then
        Action = Victory_Action
    else
        Action = Trans_Action
    end
end

function Portal_Init()
    portalThis = portalData[gameLevel + 1]  -- 1-indexed

    portalTile = portalThis.y * 32 + portalThis.x
    portalPos  = portalThis.y * 8 * WIDTH + portalThis.x * 8

    portalFlash    = 0
    portalIsReady  = 0
    Portal_Ticker  = DoNothing
end
