function doAP(ssid, password)
    wifi.setmode(wifi.STATIONAP)
    cfg={}
    cfg.ssid=ssid
    cfg.pwd=password
    wifi.ap.config(cfg)
end
