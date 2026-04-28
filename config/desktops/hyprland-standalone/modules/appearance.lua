-- Appearance, decoration and animation settings

hl.config({
    general = {
        gaps_in = 3,
        -- top, right, bottom, left
        gaps_out = { top = 100, right = 285, bottom = 220, left = 285 },
        border_size = 0,

        col = {
            active_border = {
                colors = {
                    "0xfff38ba8",
                    "0xfffab387",
                    "0xfff9e2af",
                    "0xffa6e3a1",
                    "0xff94e2d5",
                    "0xff89dceb",
                    "0xff74c7ec",
                    "0xff89b4fa",
                    "0xffcba6f7",
                    "0xfff5c2e7",
                },
                angle = 45,
            },
            inactive_border = "0xff8f909a",
        },

        layout = "scrolling",
    },

    decoration = {
        rounding = 12,

        shadow = {
            enabled = true,
            range = 10,
            render_power = 3,
            color = "0xffb4befe",
        },

        blur = {
            new_optimizations = true,
            enabled = true,
            size = 4,
            passes = 3,
        },
    },

    animations = {
        enabled = true,
    },
})

hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "default", style = "slidevert" })
hl.animation({ leaf = "windows", enabled = true, speed = 3, bezier = "default" })
hl.animation({ leaf = "layers", enabled = true, speed = 3, bezier = "default" })

return true
