-- Appearance, decoration and animation settings

hl.config({
	general = {
		gaps_in = 2,
		gaps_out = { top = 100, right = 285, bottom = 220, left = 285 },
		border_size = 0,

		layout = "scrolling",
	},

	decoration = {
		rounding = 8,

		active_opacity = 0.93,
		inactive_opacity = 0.95,

		shadow = {
			enabled = true,
			range = 8,
			render_power = 3,
			color = "0xDDb4befe",
		},

		glow = {
			enabled = true,
			range = 5,
			render_power = 3,
			color = "0xDDb4befe",
		},

		blur = {
			new_optimizations = true,
			enabled = true,
			size = 4,
			passes = 4,
			special = true,
			popups = true,
			popups_ignorealpha = 0.5,
		},
	},

	animations = {
		enabled = true,
	},
})

hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "default", style = "slidevert" })
hl.animation({ leaf = "windows", enabled = true, speed = 3, bezier = "default" })
hl.animation({ leaf = "layers", enabled = true, speed = 3, bezier = "default" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1, bezier = "default" })
hl.animation({ leaf = "fadePopupsOut", enabled = false })
hl.animation({ leaf = "fadePopupsIn", enabled = false })
return true
