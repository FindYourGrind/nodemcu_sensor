require("wifi_work")

local ip = 0
local port = 0
local url = 0

pin = 4

function parseWiFiData(data)
    s1, e1 = string.find(data, "ssid=")
    s2, e2 = string.find(data, "&", e1)
    ssid = string.sub(data, e1 + 1, s2 - 1) 
    s1, e1 = string.find(data, "password=")
    password = string.sub(data, e1 + 1, -1) 
    return ssid, password   
end

function parseServerData(data)
    s1, e1 = string.find(data, "ip=")
    s2, e2 = string.find(data, "&", e1)
    ip = string.sub(data, e1 + 1, s2 - 1) 
    
    s1, e1 = string.find(data, "port=")
    s2, e2 = string.find(data, "&", e1)
    port = string.sub(data, e1 + 1, s2 - 1)   
      
    s1, e1 = string.find(data, "url=")
    url = string.sub(data, e1 + 1, -1) 
    return ip, port, url   
end

function connect (conn, data)
   local query_data
   conn:on ("receive",
      function (cn, req_data)
         templ  = {}
         templ.head = {}
         templ.head.title = 'AREG sensor'
         templ.main = {}
         templ.main.title = 'Sensor ID: ' .. node.chipid()
         query_data = get_http_req (req_data)
         print (query_data["METHOD"] .. " " .. " " .. query_data["REQUEST"])
         if (query_data["METHOD"] == "GET") then
            if (string.find(query_data["REQUEST"], "/favicon")) then
            else
                render(cn, "index.html", "200 OK", templ)
            end
         elseif (query_data["METHOD"] == "POST") then
            if (string.find(query_data["REQUEST"], "/config_wifi")) then
                ssid, password = parseWiFiData(req_data)
                wifi_work.startClient(wifi, print, tmr, ssid, password)
                render(cn, "index.html", "200 OK", templ) 
            elseif (string.find(query_data["REQUEST"], "/config_server")) then
                ip, port, url = parseServerData(req_data)
                client.setServer(net, ip, tonumber(port), url)
                render(cn, "index.html", "200 OK", templ)
            end
         end
      conn:on("sent", function(conn)
        conn:close() 
      end)
      
      collectgarbage()
      end)
end

function get_http_req (instr)
   local t = {}
   local first = nil
   local key, v, strt_ndx, end_ndx

   for str in string.gmatch (instr, "([^\n]+)") do
      if (first == nil) then
         first = 1
         strt_ndx, end_ndx = string.find (str, "([^ ]+)")
         v = trim (string.sub (str, end_ndx + 2))
         key = trim (string.sub (str, strt_ndx, end_ndx))
         t["METHOD"] = key
         t["REQUEST"] = v
      else -- Process and reamaining ":" fields
         strt_ndx, end_ndx = string.find (str, "([^:]+)")
         if (end_ndx ~= nil) then
            v = trim (string.sub (str, end_ndx + 2))
            key = trim (string.sub (str, strt_ndx, end_ndx))
            t[key] = v
         end
      end
   end
   return t
end

function trim (s)
  return (s:gsub ("^%s*(.-)%s*$", "%1"))
end

function openStaticFile(conn, args, filename)
    file.open(filename, "r")
    while true do
        line = file.readline()
        if line == nil then break end
        conn:send(substituteParams(line, args))
    end
    file.close()
end

function substituteParams(line, args)
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

function render( conn, filename, resp,  ...)   
    conn:send('HTTP/1.1 ' .. resp .. '\nContent-Type: text/html\n\n')
    conn:send('<!DOCTYPE HTML>')
    conn:send('<html>')
    arg = {...}
    openStaticFile(conn, arg[1].head, "head.html")
    conn:send('<script>')
    openStaticFile(conn, false, "script.js")
    conn:send('</script>')
    conn:send('<style>')
    openStaticFile(conn, false, "style.css")
    conn:send('</style>')
    openStaticFile(conn, arg[1].main, filename)
    conn:send('</html>')
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
    if g.read(pin) == 0 then
        sendToServer()
        t.delay(200000)
    end
end

function sendToServer()
    conn = nil
    conn=net.createConnection(net.TCP, 0)      
    conn:on("connection", function(conn, payload) 
         conn:send("POST /" .. url
          .." HTTP/1.1\r\n" 
          .."Host: " .. ip .. "\r\n"
          .."Accept: */*\r\n" 
          .."\r\n"
          .."knock\r\n")
         conn:close()
         end)                                 
    conn:connect(tonumber(port), ip)
end

wifi_work.startAP (wifi, "SensorAP", "11111111")

srv=net.createServer(net.TCP)
srv:listen(80, connect)

gpio.mode(pin,gpio.INT,gpio.PULLUP)
gpio.trig(pin,"down", debounce(onChange))
   
