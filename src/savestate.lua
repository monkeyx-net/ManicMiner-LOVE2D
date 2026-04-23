-- savestate.lua: Save and restore complete game state, plus persistent game config

-- ---------------------------------------------------------------------------
-- Game config (starting lives / level for new games)

local CONFIG_FILE = "gameconfig.dat"

gameConfigLives = 3   -- global: starting lives for new games (1-9)
gameConfigLevel = 0   -- global: starting level for new games (0-19)

function GameConfig_Save()
    love.filesystem.write(CONFIG_FILE,
        "lives=" .. gameConfigLives .. "\nlevel=" .. gameConfigLevel)
end

function GameConfig_Load()
    local data = love.filesystem.read(CONFIG_FILE)
    if not data then return end
    for line in data:gmatch("[^\n]+") do
        local k, v = line:match("^([^=]+)=(.*)$")
        if k == "lives" then
            gameConfigLives = math.max(1, math.min(9,  tonumber(v) or 3))
        elseif k == "level" then
            gameConfigLevel = math.max(0, math.min(19, tonumber(v) or 0))
        end
    end
end

-- ---------------------------------------------------------------------------
-- Save states (5 slots: savestate_1.dat through savestate_5.dat)

local SAVE_VERSION = 1
local NUM_SLOTS    = 5

local function slotFile(slot)
    return string.format("savestate_%d.dat", slot)
end

function SaveState_Exists(slot)
    return love.filesystem.getInfo(slotFile(slot)) ~= nil
end

function SaveState_AnyExists()
    for i = 1, NUM_SLOTS do
        if SaveState_Exists(i) then return true end
    end
    return false
end

function SaveState_Delete(slot)
    love.filesystem.remove(slotFile(slot))
end

-- Returns {level, lives, score} for display, or nil if slot is empty/invalid
function SaveState_GetInfo(slot)
    local data = love.filesystem.read(slotFile(slot))
    if not data then return nil end
    local state = {}
    for line in data:gmatch("[^\n]+") do
        local k, v = line:match("^([^=]+)=(.*)$")
        if k then state[k] = v end
    end
    if tonumber(state.version) ~= SAVE_VERSION then return nil end
    return {
        level = tonumber(state.level) or 0,
        lives = tonumber(state.lives) or 3,
        score = tonumber(state.score) or 0,
    }
end

function SaveState_Save(slot)
    local parts = {}
    local function add(k, v)
        parts[#parts + 1] = k .. "=" .. tostring(v)
    end

    add("version",    SAVE_VERSION)
    add("level",      gameLevel)
    add("lives",      gameLives)
    add("air",        gameAir)
    add("kongfallen", kongFallen and 1 or 0)

    local score, hiscore = Game_GetScores()
    add("score",      score)
    add("hiscore",    hiscore)

    local md = Miner_GetSaveData()
    add("minerX",     md.x)
    add("minerY",     md.y)
    add("minerTile",  md.tile)
    add("minerAlign", md.align)
    add("minerFrame", md.frame)
    add("minerDir",   md.dir)
    add("minerAir",   md.air)
    add("jumpStage",  md.jumpStage)
    add("minerMove",  md.move)
    add("minerInk",   md.ink)

    local ld = Level_GetSaveData()
    add("itemcount",  ld.itemCount)
    parts[#parts + 1] = "tileType="     .. table.concat(ld.tileType, ",")
    parts[#parts + 1] = "tileGfx="      .. table.concat(ld.tileGfx, ",")
    parts[#parts + 1] = "collapseData=" .. table.concat(ld.collapseData, ",")

    local pd = Portal_GetSaveData()
    add("portalready", pd.ready)

    local rd = Robots_GetSaveData()
    local rx, ry, rf, rt, rs, rn, ri, rm, ra = {}, {}, {}, {}, {}, {}, {}, {}, {}
    for i = 1, 8 do
        local r = rd[i]
        rx[i] = r.x;  ry[i] = r.y;     rf[i] = r.frame
        rt[i] = r.tile; rs[i] = r.subpix; rn[i] = r.nframes
        ri[i] = r.ink; rm[i] = r.move; ra[i] = r.active
    end
    parts[#parts + 1] = "robotX="      .. table.concat(rx, ",")
    parts[#parts + 1] = "robotY="      .. table.concat(ry, ",")
    parts[#parts + 1] = "robotFrame="  .. table.concat(rf, ",")
    parts[#parts + 1] = "robotTile="   .. table.concat(rt, ",")
    parts[#parts + 1] = "robotSubpix=" .. table.concat(rs, ",")
    parts[#parts + 1] = "robotNframes=".. table.concat(rn, ",")
    parts[#parts + 1] = "robotInk="    .. table.concat(ri, ",")
    parts[#parts + 1] = "robotMove="   .. table.concat(rm, ",")
    parts[#parts + 1] = "robotActive=" .. table.concat(ra, ",")

    love.filesystem.write(slotFile(slot), table.concat(parts, "\n"))
end

function SaveState_Load(slot)
    local data = love.filesystem.read(slotFile(slot))
    if not data then return nil end

    local state = {}
    for line in data:gmatch("[^\n]+") do
        local k, v = line:match("^([^=]+)=(.*)$")
        if k then state[k] = v end
    end

    if tonumber(state.version) ~= SAVE_VERSION then return nil end

    local function parseArray(str)
        local t = {}
        for v in (str or ""):gmatch("[^,]+") do
            t[#t + 1] = tonumber(v) or 0
        end
        return t
    end

    return {
        level      = tonumber(state.level)      or 0,
        lives      = tonumber(state.lives)      or 3,
        air        = tonumber(state.air)        or 0,
        score      = tonumber(state.score)      or 0,
        hiscore    = tonumber(state.hiscore)    or 0,
        kongfallen = (tonumber(state.kongfallen) or 0) == 1,
        miner = {
            x         = tonumber(state.minerX)     or 0,
            y         = tonumber(state.minerY)      or 0,
            tile      = tonumber(state.minerTile)   or 0,
            align     = tonumber(state.minerAlign)  or 4,
            frame     = tonumber(state.minerFrame)  or 0,
            dir       = tonumber(state.minerDir)    or 0,
            air       = tonumber(state.minerAir)    or 0,
            jumpStage = tonumber(state.jumpStage)   or 0,
            move      = tonumber(state.minerMove)   or 0,
            ink       = tonumber(state.minerInk)    or 7,
        },
        level_data = {
            itemCount    = tonumber(state.itemcount) or 0,
            tileType     = parseArray(state.tileType),
            tileGfx      = parseArray(state.tileGfx),
            collapseData = parseArray(state.collapseData),
        },
        portal = {
            ready = tonumber(state.portalready) or 0,
        },
        robots = (function()
            local rx  = parseArray(state.robotX)
            local ry  = parseArray(state.robotY)
            local rf  = parseArray(state.robotFrame)
            local rt  = parseArray(state.robotTile)
            local rs  = parseArray(state.robotSubpix)
            local rn  = parseArray(state.robotNframes)
            local ri  = parseArray(state.robotInk)
            local ra  = parseArray(state.robotActive)
            local rm  = {}
            local mi  = 0
            for s in (state.robotMove or ""):gmatch("[^,]+") do
                mi = mi + 1; rm[mi] = s
            end
            local t = {}
            for i = 1, 8 do
                t[i] = {
                    x = rx[i] or 0, y = ry[i] or 0,
                    frame = rf[i] or 0, tile = rt[i] or 0,
                    subpix = rs[i] or 0, nframes = rn[i] or 0,
                    ink = ri[i] or 0, active = ra[i] or 0,
                    move = rm[i] or "none",
                }
            end
            return t
        end)(),
    }
end
