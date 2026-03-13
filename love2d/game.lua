-- game.lua: Core game state management

local AIR = 138 * WIDTH + 28

local gameMusic = MUS_PLAY

local airData = {224,224,220,220,220,220,220,220,220,224,220,220,224,224,224,224,220,220,224,224}

local levelBorder = {0xb,0x1,0xa,0xd,0xb,0x0,0x4,0x5,0x1,0x9,0x1,0x5,0xa,0x1,0xb,0xd,0x8,0x1,0x0,0x5}

local gameScore         = 0
local gameHiScore       = 0
local gameExtraLifeCount = 0

local gameFrame = 0
local gameTimer = {}

-- Globals read by other modules
gamePaused  = 0
gameLevel   = 0
gameTicks   = 0
gameDemo    = 1
gameLives   = 3
gameAir     = 0
gameAirOld  = 0

-- Function variables (global, swapped at runtime)
Game_ExtraLife = DoNothing
Game_DrawAir   = DoNothing
Spg_Drawer     = DoNothing
Miner_Ticker   = DoNothing
Miner_Drawer   = DoNothing
Portal_Ticker  = DoNothing

function Game_CheckHighScore()
    if gameScore > gameHiScore then
        gameHiScore = gameScore
    end
end

function Game_DrawLives()
    local pos = LIVES
    for l = 0, gameLives - 2 do
        Miner_DrawSeqSprite(pos, 0x0, 0x5)
        pos = pos + 16
    end
end

local function DoDrawAir()
    gameAirOld = gameAirOld - 1
    Video_AirBar(AIR + gameAirOld, 0x7)

    if gameAirOld == math.floor((gameAir + 7) / 8) then
        Game_DrawAir = DoNothing
    end
end

function Game_ReduceAir(amount)
    gameAir = gameAir - amount
    if gameAir < 0 then gameAir = 0 end

    if gameAirOld > math.floor((gameAir + 7) / 8) then
        Game_DrawAir = DoDrawAir
    end
end

local function GameDrawScore(pos, x, score, ink)
    -- Build text: escape codes + right-justified score
    local digits = {}
    for i = 1, 5 do
        digits[i] = '.'
    end
    digits[6] = '0'
    local i = 6
    local sc = score
    local d = 6
    while d > 0 and sc > 0 do
        digits[i] = string.char(string.byte('0') + (sc % 10))
        sc = math.floor(sc / 10)
        i = i - 1
        d = d - 1
    end
    -- prefix: \x01\x00\x02<ink>
    local text = "\x01\x00\x02" .. string.char(ink) .. table.concat(digits)
    Video_WriteLarge(pos, x, text)
end

function Game_DrawScore()
    GameDrawScore(SCORE, WIDTH - 6 * 8 - 4, gameScore, 0xe)
end

function Game_DrawHiScore()
    GameDrawScore(SCORE, 5 * 8 + 4, gameHiScore, 0x6)
end

local function DoExtraLife()
    gameExtraLifeCount = gameExtraLifeCount - 1
    System_Border(rshift(gameExtraLifeCount, 2))

    if gameExtraLifeCount > 0 then return end

    System_Border(levelBorder[gameLevel + 1])
    Game_ExtraLife = DoNothing
end

function Game_ScoreAdd(score)
    local previous = math.floor(gameScore / 10000)
    gameScore = gameScore + score
    Game_DrawScore()

    if math.floor(gameScore / 10000) == previous then return end

    gameLives = gameLives + 1
    Game_DrawLives()
    gameExtraLifeCount = 16 * 4  -- 16 << 2
    Game_ExtraLife = DoExtraLife
end

function Game_GotItem(tile)
    Level_TileDelete(tile)
    Game_ScoreAdd(100)

    if Level_ReduceItemCount() > 0 then return end

    if gameLevel == EUGENE then
        Robots_Eugene()
    end

    Portal_Ready()
end

local function DoGameDrawer()
    if gameMusic == MUS_PLAY then
        Game_DrawLives()
    end

    Game_DrawAir()
    Game_ExtraLife()

    if gameFrame == 0 then return end

    Video_ClearSprites()
    Level_Drawer()
    Robots_Drawer()
    Miner_Drawer()
    Level_ItemDrawer()
    Spg_Drawer()
    Portal_Drawer()
end

local function DoGameDrawOnce()
    DoGameDrawer()
    Drawer = DoNothing
end

local function DoGameTicker()
    if gameMusic == MUS_PLAY then
        Miner_IncSeq()
    end

    gameFrame = Timer_Update(gameTimer)
    if gameFrame == 0 then return end

    gameTicks = gameTicks + 1

    Level_Ticker()
    Robots_Ticker()
    Miner_Ticker()
    Portal_Ticker()

    Game_ReduceAir(1)
    if gameAir == 0 then
        Action = Die_Action
    end

    if gameDemo == 0 then return end

    if gameTicks < 64 then return end

    Action = Trans_Action
end

function Game_Pause(paused)
    if gamePaused == paused then return end

    gamePaused = paused

    if paused == 1 then
        Ticker = DoNothing
        Drawer = DoNothing
        Audio_Play(MUS_STOP)
    else
        Ticker = DoGameTicker
        Drawer = DoGameDrawer
        Audio_Play(gameMusic)
    end
end

local function DoGameInit()
    Level_Init()
    Robots_Init()
    Portal_Init()
    Portal_Ticker = DoNothing

    Miner_Init()

    if gameLevel == SPG then
        Spg_Drawer = DoSpgDrawer
    else
        Spg_Drawer = DoNothing
    end

    -- Draw air bar
    for x = 0, 223 do
        Video_AirBar(AIR + x, x < 48 and 0x2 or 0x4)
    end

    gameAirOld = 224
    gameAir    = airData[gameLevel + 1] * 8
    Game_DrawAir = DoNothing

    gameTicks = 0

    System_Border(levelBorder[gameLevel + 1])

    Timer_Set(gameTimer, 12, TICKRATE)
    gameFrame = 1  -- immediate draw

    if gamePaused == 0 then
        Audio_Play(gameMusic)
        Ticker = DoGameTicker
    else
        Ticker = DoNothing
    end
end

local function DoGameDemoResponder()
    Action = Title_Action
end

local function DoGameResponder()
    if gameInput == KEY_PAUSE then
        Game_Pause(1 - gamePaused)
    elseif gameInput == KEY_MUTE then
        gameMusic = (gameMusic == MUS_PLAY) and MUS_STOP or MUS_PLAY
        Audio_Play(gameMusic)
        Game_Pause(0)
    elseif gameInput == KEY_ESCAPE then
        Action = Title_Action
    else
        Cheat_Responder()
    end
end

function Game_GameReset()
    gameLives = 3
    gameLevel = 0
    gameScore = 0
    gamePaused = 0

    Game_ExtraLife = DoNothing
    Game_DrawHiScore()

    Miner_SetSeq(7, 20)
    Game_DrawLives()

    if cheatEnabled == 1 then
        Gameover_DrawCheat()
    end

    if gameDemo == 0 then
        Miner_Ticker = DoMinerTicker
        Miner_Drawer = DoMinerDrawer
    else
        Miner_Ticker = DoNothing
        Miner_Drawer = DoNothing
    end

    Audio_Music(MUS_GAME, MUS_STOP)
end

function Game_ChangeLevel()
    Ticker = DoGameInit
    Drawer = (gamePaused ~= 0) and DoGameDrawOnce or DoGameDrawer
    Action = DoNothing
end

function Game_Action()
    Responder = (gameDemo ~= 0) and DoGameDemoResponder or DoGameResponder
    Ticker    = DoGameInit
    Drawer    = DoGameDrawer
    Action    = DoNothing
end
