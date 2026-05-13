-- Special actions with real logic. Simple binds stay in binds.lua.

local M = {}

function M.focus_or_workspace_down()
    local before = hl.get_active_window()
    local beforeY = before and before.at and before.at.y or nil

    hl.dispatch(hl.dsp.focus({ direction = "down" }))

    local after = hl.get_active_window()
    local afterY = after and after.at and after.at.y or nil

    if afterY == nil or beforeY == nil or afterY <= beforeY then
        hl.dispatch(hl.dsp.focus({ workspace = "r+1" }))
    end
end

function M.focus_or_workspace_up()
    local before = hl.get_active_window()
    local beforeY = before and before.at and before.at.y or nil

    hl.dispatch(hl.dsp.focus({ direction = "up" }))

    local after = hl.get_active_window()
    local afterY = after and after.at and after.at.y or nil

    if afterY == nil or beforeY == nil or afterY >= beforeY then
        hl.dispatch(hl.dsp.focus({ workspace = "r-1" }))
    end
end

--- Focus an existing window matching a query, or launch the app.
---@param query table hl.get_windows filter (e.g. { class = "spotify" })
---@param focus_selector string window selector for hl.dsp.focus (e.g. "class:spotify")
---@param cmd string command to launch if no window is found
---@param launch_workspace string? optional workspace to switch to before launching
function M.focus_or_launch(query, focus_selector, cmd, launch_workspace)
    return function()
        local windows = hl.get_windows(query)

        if windows and #windows > 0 then
            hl.dispatch(hl.dsp.focus({ window = focus_selector }))
        else
            if launch_workspace then
                hl.dispatch(hl.dsp.focus({ workspace = launch_workspace }))
            end
            hl.dispatch(hl.dsp.exec_cmd(cmd))
        end
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
        hl.dispatch(hl.dsp.layout("colresize 0.5"))
    else
        hl.dispatch(hl.dsp.layout("colresize 1.0"))
    end
end

return M
