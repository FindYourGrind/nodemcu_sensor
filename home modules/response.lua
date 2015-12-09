local modname = ...
local M = {}
_G[modname] = M

setfenv(1,M)

function openStaticFile(print, file, conn, args, filename)
    file.open(filename, "r")
    while true do
        line = file.readline()
        if line == nil then break end
        conn:send(substituteParams(print, line, args))
    end
    file.close()
end

function substituteParams(print, line, args)
    regExpTempl = '<\+\+.+\+\+>'
    regExpParam = '%a+'
    l = line
    x, y = line:find(regExpTempl)
    if y then
        local tmpLine = line:sub(x, y)
        local param = tmpLine:sub(tmpLine:find(regExpParam))
        l = line:gsub(regExpTempl, args[param])
    end
    return l
end

function render(print, file, conn, filename, resp,  ...)   
    
    conn:send('HTTP/1.1 ' .. resp .. '\nContent-Type: text/html\n\n')
    conn:send('<!DOCTYPE HTML>')
    conn:send('<html>')
    arg = {...}

    openStaticFile(print, file, conn, arg[1].head, "head.html")

    conn:send('<script>')
    openStaticFile(print, file, conn, false, "script.js")
    conn:send('</script>')

    openStaticFile(print, file, conn, arg[1].main, filename)
    
    conn:send('</html>')
end

return M
