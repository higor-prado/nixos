-- Keybindings migrated to Hyprland Lua API.
-- Special actions with real logic live in modules/actions.lua.

local actions = require("modules.actions")

hl.config({
    binds = {
        drag_threshold = 10,
    },
})

-- Application Launchers
hl.bind("SUPER + SPACE", hl.dsp.exec_cmd([[pkill -x rofi || rofi -show drun -theme ~/.config/rofi/launchers/type-3/style-1.rasi]]))
hl.bind("SUPER + CTRL + T", hl.dsp.exec_cmd("kitty"))
hl.bind("SUPER + CTRL + F", hl.dsp.exec_cmd("nautilus"))
hl.bind("SUPER + CTRL + B", hl.dsp.exec_cmd("firefox"))
hl.bind("SUPER + CTRL + Z", hl.dsp.exec_cmd("zeditor"))
hl.bind("SUPER + CTRL + C", hl.dsp.exec_cmd("code"))
hl.bind("SUPER + CTRL + V", hl.dsp.exec_cmd("~/.config/waybar/scripts/clipboard-history.sh"))
hl.bind("SUPER + CTRL + O", hl.dsp.exec_cmd("obsidian"))
hl.bind("SUPER + CTRL + E", hl.dsp.exec_cmd([=[emacsclient -c -a ""]=]))
hl.bind("SUPER + CTRL + 7", hl.dsp.exec_cmd("zeditor"))
hl.bind("SUPER + CTRL + 8", hl.dsp.exec_cmd("teams-for-linux"))
hl.bind("SUPER + CTRL + 9", hl.dsp.exec_cmd("steam"))
hl.bind("SUPER + CTRL + 0", hl.dsp.exec_cmd("spotify"))
hl.bind("ALT + F4", hl.dsp.window.close())

-- Window Management
hl.bind("SUPER + M", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind("SUPER + KP_Multiply", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind("SUPER + ALT + slash", hl.dsp.window.float())
hl.bind("SUPER + ALT + KP_Divide", hl.dsp.window.float())
hl.bind("SUPER + comma", hl.dsp.layout("center"))
hl.bind("SUPER + KP_Delete", actions.toggle_col_width)
hl.bind("SUPER + period", actions.toggle_col_width)
hl.bind("SUPER + KP_Insert", actions.toggle_col_width)

-- Power menu
hl.bind("SUPER + CTRL + Delete", hl.dsp.exec_cmd("~/.config/rofi/powermenu/type-2/powermenu.sh"))

-- Scroll
hl.bind("mouse_left", hl.dsp.layout("focus l"))
hl.bind("mouse_right", hl.dsp.layout("focus r"))

hl.bind("SUPER + mouse_left", hl.dsp.focus({ workspace = "r-1" }))
hl.bind("SUPER + mouse_right", hl.dsp.focus({ workspace = "r+1" }))
hl.bind("SUPER + ALT + mouse_left", hl.dsp.layout("swapcol l"))
hl.bind("SUPER + ALT + mouse_right", hl.dsp.layout("swapcol r"))
hl.bind("SUPER + SHIFT + mouse_left", hl.dsp.layout("colresize +0.1"))
hl.bind("SUPER + SHIFT + mouse_right", hl.dsp.layout("colresize -0.1"))

-- Scroll Wheel Navigation
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "r-1" }))
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "r+1" }))
hl.bind("SUPER + CTRL + mouse_down", hl.dsp.window.move({ workspace = "r-1" }))
hl.bind("SUPER + CTRL + mouse_up", hl.dsp.window.move({ workspace = "r+1" }))
hl.bind("SUPER + ALT + mouse_down", hl.dsp.layout("swapcol l"))
hl.bind("SUPER + ALT + mouse_up", hl.dsp.layout("swapcol r"))
hl.bind("SUPER + SHIFT + mouse_down", hl.dsp.layout("colresize +0.1"))
hl.bind("SUPER + SHIFT + mouse_up", hl.dsp.layout("colresize -0.1"))

-- Knobs (Epomaker EK21: XF86Audio keys -> navigation)
hl.bind("XF86AudioRaiseVolume", hl.dsp.layout("focus r"))
hl.bind("XF86AudioLowerVolume", hl.dsp.layout("focus l"))

hl.bind("XF86AudioMute", actions.toggle_col_width)

hl.bind("SUPER + XF86AudioRaiseVolume", hl.dsp.focus({ workspace = "r+1" }))
hl.bind("SUPER + XF86AudioLowerVolume", hl.dsp.focus({ workspace = "r-1" }))
hl.bind("SUPER + XF86AudioMute", hl.dsp.layout("center"))

hl.bind("ALT + XF86AudioRaiseVolume", hl.dsp.layout("focus r"))
hl.bind("ALT + XF86AudioLowerVolume", hl.dsp.layout("focus l"))

hl.bind("SUPER + CTRL + XF86AudioRaiseVolume", hl.dsp.window.move({ workspace = "r+1" }))
hl.bind("SUPER + CTRL + XF86AudioLowerVolume", hl.dsp.window.move({ workspace = "r-1" }))

hl.bind("SUPER + CTRL + ALT + XF86AudioRaiseVolume", hl.dsp.window.move({ direction = "down" }))
hl.bind("SUPER + CTRL + ALT + XF86AudioLowerVolume", hl.dsp.window.move({ direction = "up" }))

hl.bind("SUPER + ALT + XF86AudioRaiseVolume", hl.dsp.layout("swapcol r"))
hl.bind("SUPER + ALT + XF86AudioLowerVolume", hl.dsp.layout("swapcol l"))

hl.bind("SUPER + SHIFT + XF86AudioRaiseVolume", hl.dsp.layout("colresize +0.1"))
hl.bind("SUPER + SHIFT + XF86AudioLowerVolume", hl.dsp.layout("colresize -0.1"))
hl.bind("SUPER + SHIFT + XF86AudioMute", hl.dsp.layout("colresize 0.5"))

-- Audio (Ctrl + Knob)
hl.bind("CTRL + XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true })
hl.bind("CTRL + XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true })
hl.bind("CTRL + XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })

-- Audio (keyboard backup)
hl.bind("SUPER + CTRL + ALT + SHIFT + equal", hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true })
hl.bind("SUPER + CTRL + ALT + SHIFT + minus", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true })
hl.bind("SUPER + CTRL + ALT + SHIFT + M", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })

-- Media Controls
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- Screenshots
hl.bind("SUPER + SHIFT + 4", hl.dsp.exec_cmd([=[grim -g "$(slurp)" - | wl-copy]=]))
hl.bind("SUPER + SHIFT + 3", hl.dsp.exec_cmd("grim - | wl-copy"))

-- Focus Navigation
hl.bind("SUPER + left", hl.dsp.layout("focus l"))
hl.bind("SUPER + right", hl.dsp.layout("focus r"))
hl.bind("SUPER + down", actions.focus_or_workspace_down)
hl.bind("SUPER + up", actions.focus_or_workspace_up)

hl.bind("SUPER + H", hl.dsp.layout("focus l"))
hl.bind("SUPER + L", hl.dsp.layout("focus r"))
hl.bind("SUPER + J", actions.focus_or_workspace_down)
hl.bind("SUPER + K", actions.focus_or_workspace_up)

-- Move Windows
hl.bind("SUPER + ALT + left", hl.dsp.layout("swapcol l"))
hl.bind("SUPER + ALT + right", hl.dsp.layout("swapcol r"))
hl.bind("SUPER + ALT + H", hl.dsp.layout("swapcol l"))
hl.bind("SUPER + ALT + L", hl.dsp.layout("swapcol r"))
hl.bind("SUPER + ALT + down", hl.dsp.window.move({ direction = "down" }))
hl.bind("SUPER + ALT + up", hl.dsp.window.move({ direction = "up" }))
hl.bind("SUPER + ALT + J", hl.dsp.window.move({ direction = "down" }))
hl.bind("SUPER + ALT + K", hl.dsp.window.move({ direction = "up" }))

-- Move Window to Workspace (vertical)
hl.bind("SUPER + CTRL + down", hl.dsp.window.move({ workspace = "r+1" }))
hl.bind("SUPER + CTRL + up", hl.dsp.window.move({ workspace = "r-1" }))
hl.bind("SUPER + CTRL + J", hl.dsp.window.move({ workspace = "r+1" }))
hl.bind("SUPER + CTRL + K", hl.dsp.window.move({ workspace = "r-1" }))

-- Workspace Navigation
hl.bind("SUPER + 1", hl.dsp.focus({ workspace = "1" }))
hl.bind("SUPER + 2", hl.dsp.focus({ workspace = "2" }))
hl.bind("SUPER + 3", hl.dsp.focus({ workspace = "3" }))
hl.bind("SUPER + 4", hl.dsp.focus({ workspace = "4" }))
hl.bind("SUPER + CTRL + 1", hl.dsp.window.move({ workspace = "1" }))
hl.bind("SUPER + CTRL + 2", hl.dsp.window.move({ workspace = "2" }))
hl.bind("SUPER + CTRL + 3", hl.dsp.window.move({ workspace = "3" }))
hl.bind("SUPER + CTRL + 4", hl.dsp.window.move({ workspace = "4" }))

-- Column Sizing
hl.bind("SUPER + bracketleft", hl.dsp.layout("colresize -0.1"))
hl.bind("SUPER + bracketright", hl.dsp.layout("colresize +0.1"))
hl.bind("SUPER + G", hl.dsp.layout("colresize +conf"))
hl.bind("SUPER + SHIFT + Return", hl.dsp.layout("colresize 0.5"))


-- ALT + LMB: move a window by dragging more than drag_threshold.
hl.bind("ALT + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + E", hl.dsp.window.float({ action = "toggle" }))

return true
