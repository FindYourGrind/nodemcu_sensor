local modname = ...
local M = {}
_G[modname] = M

setfenv(1,M)

local i = 0
local p = 0
local u = 0
local n = 0

function setServer(net, ip, port, url)
    local i = ip
    local p = port
    local u = url
    local n = net
end

function sendToServer()

end

return M