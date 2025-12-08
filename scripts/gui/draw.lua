local mp = require 'mp'
local assdraw = require 'mp.assdraw'

local M = {}

local function timestamp(seconds)
    if not seconds then return "0:00" end
    local hrs = math.floor(seconds / 3600)
    local min = math.floor((seconds % 3600) / 60)
    local sec = math.floor(seconds % 60)
    if hrs > 0 then
        return string.format("%d:%02d:%02d", hrs, min, sec)
    else
        return string.format("%d:%02d", min, sec)
    end
end

function M.draw(state, opts)
    if not state.show_ui and not state.paused and not state.dragging then
        mp.set_osd_ass(state.w, state.h, "")
        return
    end

    local ass = assdraw.ass_new()
    local w, h = state.w, state.h
    
    -- 1. Gradient Background
    ass:new_event()
    ass:append("{\\pos(0,0)\\r\\shad0\\bord0\\an7}")
    ass:append("{\\c&H000000&\\alpha&H40&}")
    ass:draw_start()
    ass:rect_cw(0, h - opts.box_height, w, h)
    ass:draw_stop()
    
    -- 2. Progress Bar Calculation
    local bar_h = (state.hovering_bar or state.dragging) and opts.bar_hover_height or opts.bar_height
    local bar_y_pos = h - opts.box_height + ((state.hovering_bar or state.dragging) and -2 or 0)
    
    -- VISUALIZACIÓN TIPO MODERN.LUA:
    -- Si arrastramos, la barra debe responder al ratón (visual_seek_pct), no al video.
    local progress = 0
    if state.dragging and state.visual_seek_pct >= 0 then
        progress = state.visual_seek_pct
    elseif state.duration > 0 then
        progress = state.position / state.duration
    end
    
    -- Background Bar
    ass:new_event()
    ass:append(string.format("{\\bord0\\shad0\\c&H%s&\\alpha&H%s&}", "FFFFFF", "BB"))
    ass:pos(0, bar_y_pos)
    ass:draw_start()
    ass:rect_cw(0, 0, w, bar_h)
    ass:draw_stop()
    
    -- Played Bar
    if progress > 0 then
        ass:new_event()
        ass:append(string.format("{\\bord0\\shad0\\c&H%s&\\alpha&H00&}", opts.color_played))
        ass:pos(0, bar_y_pos)
        ass:draw_start()
        ass:rect_cw(0, 0, w * progress, bar_h)
        ass:draw_stop()
        
        -- Handle (Knob)
        if state.hovering_bar or state.dragging then
           ass:new_event()
           ass:append(string.format("{\\bord0\\shad0\\c&H%s&}", opts.color_played))
           ass:pos(w * progress, bar_y_pos + bar_h/2)
           ass:draw_start()
           ass:round_rect_cw(-opts.handle_size/2, -opts.handle_size/2, opts.handle_size/2, opts.handle_size/2, opts.handle_size/4)
           ass:draw_stop()
        end
    end

    -- 3. Controls (Play/Pause & Time)
    local icon_y = h - opts.box_height / 2
    local cur_x = 20
    
    ass:new_event()
    ass:pos(cur_x, icon_y)
    ass:append("{\\bord0\\shad0\\c&HFFFFFF&}")
    ass:draw_start()
    if state.paused then
        ass:move_to(0, -10)
        ass:line_to(15, 0)
        ass:line_to(0, 10)
    else
        ass:rect_cw(0, -10, 5, 10)
        ass:rect_cw(10, -10, 15, 10)
    end
    ass:draw_stop()
    
    cur_x = cur_x + 40
    ass:new_event()
    ass:pos(cur_x, icon_y)
    ass:an(4)
    ass:append(string.format("{\\fs%d\\bord1\\shad0\\1c&HFFFFFF&\\3c&H000000&}", opts.font_size))
    
    -- Si arrastramos, mostramos el tiempo objetivo, no el actual
    local time_to_show = state.position
    if state.dragging and state.visual_seek_pct >= 0 then
        time_to_show = state.visual_seek_pct * state.duration
    end
    ass:append(timestamp(time_to_show) .. " / " .. timestamp(state.duration))
    
    mp.set_osd_ass(state.w, state.h, ass.text)
end

return M
