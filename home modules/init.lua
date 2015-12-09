require('response')

local ip = "192.168.1.146"
local port = "8080"
local url = "sensor"

f = loadfile("doAP.lc")
f()
doAP("SensorAP", "11111111")
f = nil

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

function debounce (func)
    local last = 0
    local delay = 200000

    return function (...)
        local now = tmr.now()
        if now - last < delay then return end
        last = now
        return func(...)
    end
end

function onChange()
    if gpio.read(4) == 0 then
        sendToServer()
        tmr.delay(200000)
    end
end

gpio.mode(4,gpio.INT,gpio.PULLUP)
gpio.trig(4,"down", debounce(onChange))

function sendToServer()
    conn = nil
    conn=net.createConnection(net.TCP, 0)      
    conn:on("connection", function(conn, payload) 
         conn:send("POST /" .. url .." HTTP/1.1\r\n" 
          .."Host: " .. ip .. "\r\n" .."Accept: */*\r\n" .."\r\n"
          .."knock\r\n")
         conn:close()
         end)                                 
    conn:connect(tonumber(port), ip)
end

srv=net.createServer(net.TCP)
srv:listen(80,function(conn)
         conn:on("receive",function(conn,request)
             local route = get_http_req_method(request)  
             local templ  = {}
             templ.head = {}
             templ.head.title = 'Sensor Server'
             templ.main = {}
             templ.main.title = 'Sensor ID: ' .. node.chipid()
             if wifi.sta.getip ( ) == nil then
                templ.main.ip = 'Sensor is not connected to AP'
             else
                templ.main.ip = 'Sensor STATION IP: ' .. wifi.sta.getip ( )
             end
             
             if string.find(request, "GET") then
                 print("GET", route)
                 response.render(print, file, conn, "index.html", "200 OK", templ)
             elseif string.find(request, "POST") then
                 print("POST", route)
                 if (string.find(route, "/wificonfig")) then
                     response.render(print, file, conn, "index.html", "200 OK", templ)
                     ssid, password = parseWiFiData(request)
                     wifi.setmode(wifi.STATIONAP)
                     wifi.sta.config (ssid, password)
                     wifi.sta.autoconnect (1)
                 elseif (string.find(route, "/serverconfig")) then
                     ip, port, url = parseServerData(request)
                     response.render(print, file, conn, "index.html", "200 OK", templ)
                 end              
             end  
         end)        
           
         conn:on("sent",function(conn)
             conn:close() 
         end)
     end)

function get_http_req_method (instr)
    local t = {}
    local str = string.sub(instr, 0, 200)
    local v = string.gsub(split(str, ' ')[2], '+', ' ')
    return v
end

function split(str, splitOn)
    if (splitOn=='') then return false end
    local pos,arr = 0,{}
    for st,sp in function() return string.find(str,splitOn,pos,true) end do
        table.insert(arr,string.sub(str,pos,st-1))
        pos = sp + 1
    end
    table.insert(arr,string.sub(str,pos))
    return arr
end
