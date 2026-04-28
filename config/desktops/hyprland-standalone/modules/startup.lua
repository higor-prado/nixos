-- Startup commands. Session/bootstrap is handled by session-bootstrap.lua.

hl.on("hyprland.start", function()
    hl.exec_cmd("hypr-dock")
end)

return true
