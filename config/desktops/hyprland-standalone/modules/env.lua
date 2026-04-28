-- Environment, cursor, misc and XWayland settings

hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")

-- Let NixOS and Home Manager handle Qt, Gtk, and Cursor themes.
-- Removed hardcoded QT_QPA_PLATFORMTHEME, XDG_CURRENT_DESKTOP, and XCURSOR_THEME 
-- since they are properly exported by the Nix session bootstrap and theme modules.

hl.on("hyprland.start", function()
    -- Sync cursor to the actual Wayland runtime using hl.exec_cmd 
    -- (Home Manager provides XCURSOR_THEME/SIZE but Hyprland may need an explicit setcursor)
    local cursor_theme = os.getenv("XCURSOR_THEME") or "phinger-cursors-dark"
    local cursor_size = os.getenv("XCURSOR_SIZE") or "24"
    hl.exec_cmd("hyprctl setcursor " .. cursor_theme .. " " .. cursor_size)
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
