local mp = require 'mp'

local M = {}

-- Local references to be injected via init
local state
local opts
local draw_fn

local function get_virtual_mouse_pos()
    local x, y = mp.get_mouse_pos()
    return x, y
end

function M.init(s, o, d)
    state = s
    opts = o
    draw_fn = d
end

function M.input_handler(event)
    state.mouse_x, state.mouse_y = get_virtual_mouse_pos()
    state.user_activity = true
    
    local bar_y_start = state.h - opts.box_height - 10
    local bar_y_end = state.h - opts.box_height + opts.bar_hover_height + 10
    
    state.hovering_bar = (state.mouse_y >= bar_y_start and state.mouse_y <= bar_y_end)
    
    if state.dragging then
        local pct = state.mouse_x / state.w
        pct = math.max(0, math.min(1, pct))
        
        -- Actualización visual suave inmediata
        state.visual_seek_pct = pct 
        
        if math.abs(pct - state.last_seek_pct) > 0.001 then
            -- CAMBIO AQUÍ: Usamos "keyframes" en lugar de "exact" para velocidad
            mp.commandv("seek", pct * 100, "absolute-percent+keyframes")
            state.last_seek_pct = pct
        end
    end
    
    if draw_fn then draw_fn() end
end

function M.mouse_handler(table)
    if table.event == "down" then
        if state.hovering_bar then
            mp.set_property("window-dragging", "no")
            state.dragging = true
            M.input_handler() 
        else
            mp.set_property("window-dragging", "yes")
            if state.mouse_x < 60 and state.mouse_y > (state.h - opts.box_height) then
                mp.command("cycle pause")
                mp.set_property("window-dragging", "no")
            else
                mp.command("cycle pause")
            end
        end
    
    elseif table.event == "up" then
        -- Si estábamos arrastrando, hacemos un seek EXACTO final
        if state.dragging and state.visual_seek_pct >= 0 then
            mp.commandv("seek", state.visual_seek_pct * 100, "absolute-percent+exact")
        end

        -- Fin del arrastre
        state.dragging = false
        state.last_seek_pct = -1
        state.visual_seek_pct = -1
        mp.set_property("window-dragging", "yes")
    end
end

return M
