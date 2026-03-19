function love.conf(t)
    t.window.title = "Manic Miner"
    t.identity = t.window.title:gsub(" ", "")
    t.window.width = 768   -- 256 * 3
    t.window.height = 576  -- 192 * 3
    t.window.resizable = true
    t.window.minwidth = 256
    t.window.minheight = 192
    t.window.vsync = 0  -- disabled: sleep-based cap used instead (reliable on ARM/RK3326)
    t.version = "11.5"
    t.console = false
end
