-- Environment, cursor, misc and XWayland settings

hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")

hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("QT_QPA_PLATFORMTHEME", "gtk3")
hl.env("QT_QPA_PLATFORMTHEME_QT6", "gtk3")

-- Required by scripts/apps launched from Hyprland (e.g. rofi powermenu logout path).
-- The third arg also imports the value into dbus/systemd user env.
hl.env("XDG_CURRENT_DESKTOP", "Hyprland", true)
hl.env("XDG_SESSION_DESKTOP", "Hyprland", true)
hl.env("XDG_SESSION_TYPE", "wayland", true)
hl.env("DESKTOP_SESSION", "hyprland", true)

hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "phinger-cursors-dark")
-- The old config set XCURSOR_SIZE twice; the final effective value was 32.
hl.env("XCURSOR_SIZE", "32")

hl.on("hyprland.start", function()
    hl.exec_cmd("hyprctl setcursor phinger-cursors-dark 24")
end)

hl.config({
    cursor = {
        no_warps = true,
    },

    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
    },

    xwayland = {
        force_zero_scaling = true,
    },
})

return true
