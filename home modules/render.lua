local modname = ...
local M = {}
_G[modname] = M

setfenv(1,M)

function render(file, conn, filename, resp,  ...)   
    conn:send('HTTP/1.1 ' .. resp .. '\nContent-Type: text/html\n\n')
    conn:send('<!DOCTYPE HTML>')
    conn:send('<html>')

    file.open("head.html", "r")
    while true do
        line = file.readline()
        if line == nil then break end
        conn:send(line)
    end
    file.close()

    conn:send('<script>')
    file.open("script.js", "r")
    while true do
        line = file.readline()
        if line == nil then break end
        conn:send(line)
    end
    file.close()
    conn:send('</script>')

    conn:send('<style>')
    file.open("style.css", "r")
    while true do
        line = file.readline()
        if line == nil then break end
        conn:send(line)
    end
    file.close()
    conn:send('</style>')

    file.open(filename, "r")
    while true do
        line = file.readline()
        if line == nil then break end
        conn:send(line)
    end
    file.close()
    
    conn:send('</html>')
end

return M