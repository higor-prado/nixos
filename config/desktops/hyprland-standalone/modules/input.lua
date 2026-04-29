-- Input configuration

hl.config({
    input = {
        kb_layout = "us",
        kb_variant = "alt-intl",
        kb_model = "pc105",
        kb_options = "numpad:microsoft",
        numlock_by_default = true,
        follow_mouse = 2,
        float_switch_override_focus = 1,
        mouse_refocus = false,

        touchpad = {
            natural_scroll = true,
            tap_to_click = true,
        },
    },
})

return true
