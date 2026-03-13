-- main.lua: Love2D entry point for Manic Miner

-- Load modules that don't need Love2D graphics API at parse time
require("common")
require("misc")

-- -----------------------------------------------------------------------------
-- Love2D callbacks

function love.load()
    -- Load remaining modules (graphics API now available)
    require("video")
    require("audio")
    require("levels")
    require("miner")
    require("robots")
    require("portal")
    require("spg")
    require("cheat")
    require("game")
    require("die")
    require("trans")
    require("gameover")
    require("victory")
    require("title")
    require("loader")

    -- Window title
    love.window.setTitle("Manic Miner")

    -- Hide mouse cursor
    love.mouse.setVisible(false)

    -- Initialize video pixel buffer (creates ImageData + Image)
    Video_Init()

    -- Initialize audio
    Audio_Init()

    -- Detect any already-connected gamepad
    for _, js in ipairs(love.joystick.getJoysticks()) do
        if js:isGamepad() then
            activeGamepad = js
            break
        end
    end

    -- Start at the loader screen
    Action = Loader_Action
end

local tickAccum = 0
local tickStep  = 1 / TICKRATE   -- seconds per game tick

function love.update(dt)
    -- Update audio every frame regardless of tick rate
    Audio_Update(dt)

    -- Accumulate time and run game logic at fixed 60 Hz
    tickAccum = tickAccum + dt
    while tickAccum >= tickStep do
        tickAccum = tickAccum - tickStep

        if Action ~= DoNothing then
            Action()
        end

        if Ticker ~= DoNothing then
            Ticker()
        end

        if Drawer ~= DoNothing then
            Drawer()
        end

        Video_Flush()
    end
end

function love.draw()
    -- Draw border colour
    local bc = borderColor
    love.graphics.setBackgroundColor(bc[1], bc[2], bc[3])
    love.graphics.clear(bc[1], bc[2], bc[3])

    -- Draw game viewport
    local sx, sy, sw, sh = Video_Viewport(love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(screenImage, sx, sy, 0, sw / WIDTH, sh / HEIGHT)
end

function love.keypressed(key, scancode, isrepeat)
    if isrepeat then return end

    -- Map Love2D key to game key code
    local mapped = KEY_NONE

    if key == "return" or key == "kpenter" then
        mapped = KEY_ENTER
    elseif key == "escape" then
        mapped = KEY_ESCAPE
    elseif key == "pause" then
        mapped = KEY_PAUSE
    elseif key == "tab" or key == "lalt" or key == "ralt" then
        mapped = KEY_JUMP
    elseif key == "0" then mapped = KEY_0
    elseif key == "1" then mapped = KEY_1
    elseif key == "2" then mapped = KEY_2
    elseif key == "3" then mapped = KEY_3
    elseif key == "4" then mapped = KEY_4
    elseif key == "5" then mapped = KEY_5
    elseif key == "6" then mapped = KEY_6
    elseif key == "7" then mapped = KEY_7
    elseif key == "8" then mapped = KEY_8
    elseif key == "9" then mapped = KEY_9
    else
        mapped = KEY_ELSE
    end

    gameInput = mapped

    if gameInput ~= KEY_NONE and Responder ~= DoNothing then
        Responder()
    end

    gameInput = KEY_NONE
end

function love.keyreleased(key)
    -- No action needed; key state is polled via System_IsKey (love.keyboard.isDown)
end

-- Gamepad button -> game key event mapping
local gamepadButtonMap = {
    a     = KEY_JUMP,
    b     = KEY_JUMP,
    x     = KEY_PAUSE,
    y     = KEY_MUTE,
    start = KEY_ENTER,
    back  = KEY_ESCAPE,
}

function love.gamepadpressed(joystick, button)
    local mapped = gamepadButtonMap[button]
    if mapped then
        gameInput = mapped
        if gameInput ~= KEY_NONE and Responder ~= DoNothing then
            Responder()
        end
        gameInput = KEY_NONE
    end
end

function love.joystickadded(joystick)
    if joystick:isGamepad() and not activeGamepad then
        activeGamepad = joystick
    end
end

function love.joystickremoved(joystick)
    if activeGamepad == joystick then
        activeGamepad = nil
        -- Pick another gamepad if available
        for _, js in ipairs(love.joystick.getJoysticks()) do
            if js:isGamepad() then
                activeGamepad = js
                break
            end
        end
    end
end

function love.quit()
    -- Clean up audio
    Audio_Shutdown()
    return false  -- allow quit
end
