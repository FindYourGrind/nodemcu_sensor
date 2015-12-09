local modname = ...
local M = {}
_G[modname] = M

setfenv(1,M)

function startAP (wifi, ssid, pass)
    wifi.setmode(wifi.STATIONAP)
    -- Declare configuration variable
    cfg={}
    cfg.ssid = ssid
    cfg.pwd = pass
    -- Pass to access point and configure
    wifi.ap.config(cfg)
end

function startClient (wifi, print, tmr, ssid, pass)
    wifi.setmode(wifi.STATIONAP)
    
    wifi.sta.config (ssid, pass)
    wifi.sta.autoconnect (1)
    
    -- Hang out until we get a wifi connection before the httpd server is started.
    wait_for_wifi_conn (print, tmr, wifi)
end

function wait_for_wifi_conn (print, tmr, wifi)
   tmr.alarm (1, 1000, 1, function ( )
      if wifi.sta.getip ( ) == nil then
         print ("Waiting for Wifi connection")
      else
         tmr.stop (1)
         print ("ESP8266 mode is: " .. wifi.getmode ( ))
         print ("The module MAC address is: " .. wifi.ap.getmac ( ))
         print ("Config done, IP is " .. wifi.sta.getip ( ))
      end
   end)
end

return M
