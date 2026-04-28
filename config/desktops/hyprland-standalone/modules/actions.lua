-- Special actions with real logic. Simple binds stay in binds.lua.

local M = {}

function M.focus_or_workspace_down()
    local before = hl.get_active_window()
    local beforeY = before and before.at and before.at.y or nil

    hl.dsp.focus({ direction = "down" })()

    local after = hl.get_active_window()
    local afterY = after and after.at and after.at.y or nil

    if afterY == nil or beforeY == nil or afterY <= beforeY then
        hl.dsp.focus({ workspace = "r+1" })()
    end
end

function M.focus_or_workspace_up()
    local before = hl.get_active_window()
    local beforeY = before and before.at and before.at.y or nil

    hl.dsp.focus({ direction = "up" })()

    local after = hl.get_active_window()
    local afterY = after and after.at and after.at.y or nil

    if afterY == nil or beforeY == nil or afterY >= beforeY then
        hl.dsp.focus({ workspace = "r-1" })()
    end
end

function M.toggle_col_width()
    local win = hl.get_active_window()
    if not win or not win.size or not win.size.x then
        return
    end

    local mon = win.monitor or hl.get_active_monitor()
    if not mon or not mon.width or not mon.scale or mon.scale == 0 then
        return
    end

    local threshold = (mon.width / mon.scale) * 0.60

    if win.size.x > threshold then
        hl.dsp.layout("colresize 0.5")()
    else
        hl.dsp.layout("colresize 1.0")()
    end
end

return M
