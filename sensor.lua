local modname = ...
local M = {}
_G[modname] = M

setfenv(1,M)

local g = 0
local t = 0
local p = 0
local Bpin = 0
local f = 0

function setSensor(gpio, tmr, print, pin)
    gpio.mode(pin,gpio.INT,gpio.PULLUP)
    g = gpio
    t = tmr
    p = print
    Bpin = pin
end

function debounce (func)
    local last = 0
    local delay = 200000

    return function (...)
        local now = t.now()
        if now - last < delay then return end

        last = now
        return func(...)
    end
end

function onChange()
    if g.read(Bpin) == 0 then
        f()
        t.delay(200000)
    end
end

function setSensorEvent(func)
    f = func
    g.trig(Bpin,"down", debounce(onChange))
end

return M
