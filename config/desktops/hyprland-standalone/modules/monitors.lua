-- Monitor configuration

hl.monitor({
    output = "eDP-1",
    disabled = true,
})

hl.monitor({
    output = "HDMI-A-1",
    mode = "3840x2160@144",
    position = "0x0",
    scale = "1.5",
})

return true
