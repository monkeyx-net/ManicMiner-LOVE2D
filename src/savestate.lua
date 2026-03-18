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
-- Save states

local SAVE_FILE    = "savestate.dat"
local SAVE_VERSION = 1

function SaveState_Exists()
    return love.filesystem.getInfo(SAVE_FILE) ~= nil
end

function SaveState_Delete()
    love.filesystem.remove(SAVE_FILE)
end

function SaveState_Save()
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

    love.filesystem.write(SAVE_FILE, table.concat(parts, "\n"))
end

function SaveState_Load()
    local data = love.filesystem.read(SAVE_FILE)
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
    }
end
