-- misc.lua: Timer implementation matching the C original

function Timer_Set(timer, numerator, divisor)
    timer.acc       = 0
    timer.rate      = math.floor(numerator / divisor)
    timer.remainder = numerator - timer.rate * divisor
    timer.divisor   = divisor
end

function Timer_Update(timer)
    timer.acc = timer.acc + timer.remainder
    if timer.acc < timer.divisor then
        return timer.rate
    end
    timer.acc = timer.acc - timer.divisor
    return timer.rate + 1
end

function Timer_New(numerator, divisor)
    local t = {acc=0, rate=0, remainder=0, divisor=1}
    Timer_Set(t, numerator, divisor)
    return t
end
