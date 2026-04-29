-- Window and layer rules

local function wr(spec)
    return hl.window_rule(spec)
end

local function lr(spec)
    return hl.layer_rule(spec)
end

local function wk(spec)
    return hl.workspace_rule(spec)
end

-- Floating utility windows
wr({ name = "float-thunar", match = { class = [=[^thunar$]=] }, float = true })
wr({ name = "float-nautilus", match = { class = [=[^org\.gnome\.Nautilus$]=] }, float = true })
wr({ name = "float-file-roller", match = { class = [=[^org.gnome.FileRoller$]=] }, float = true })
wr({ name = "float-calculator", match = { class = [=[^gnome-calculator$]=] }, float = true })
wr({ name = "float-blueman", match = { class = [=[^.blueman-manager-wrapped$]=] }, float = true })
wr({ name = "float-waypaper", match = { class = [=[^waypaper$]=] }, float = true })
wr({ name = "nemo-properties", match = { class = [=[^nemo$]=], title = [=[.*Properties]=] }, float = true })

-- Focus opacity
wr({ name = "focused-opacity", match = { focus = true }, opacity = "0.93" })
wr({ name = "unfocused-opacity", match = { focus = false }, opacity = "0.95", no_shadow = true })

-- Video/content rules
wr({ name = "video-youtube", match = { title = [=[.*YouTube.*]=] }, opacity = "1.0 override" })
wr({ name = "video-hbo", match = { title = [=[.*HBO.*]=] }, opacity = "1.0 override" })
wr({ name = "video-prime", match = { title = [=[.*Prime Video.*]=] }, opacity = "1.0 override" })
wr({ name = "video-netflix", match = { title = [=[.*Netflix.*]=] }, opacity = "1.0 override" })
wr({ name = "video-disney", match = { title = [=[.*Disney.*]=] }, opacity = "1.0 override" })
wr({ name = "video-twitch", match = { title = [=[.*Twitch.*]=] }, opacity = "1.0 override" })
wr({ name = "video-kick", match = { title = [=[.*Kick.*]=] }, opacity = "1.0 override" })
wr({ name = "video-pip", match = { title = [=[^Picture-in-Picture$]=] }, opacity = "1.0 override" })

-- Layer rules
lr({ name = "waybar-blur", match = { namespace = [=[^waybar$]=] }, blur = true, ignore_alpha = 0.49, no_anim = true })
lr({ name = "walker-blur", match = { namespace = [=[^walker$]=] }, blur = true, ignore_alpha = 0.9, no_anim = true })

wk({ workspace = "special:scratchpad", on_created_empty = "kitty", })

return true
