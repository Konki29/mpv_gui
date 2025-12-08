local mp = require 'mp'
local Element = require 'elements.Element'
local ProgressBar = setmetatable({}, {__index = Element})
ProgressBar.__index = ProgressBar

function ProgressBar.new(state, opts)
    local self = Element.new(state, opts)
    return setmetatable(self, ProgressBar)
end

function ProgressBar:is_hovering(x, y)
    -- La barra está en la fila superior (bar_row_offset desde abajo)
    local bar_visual_y = self.state.h - self.opts.bar_row_offset
    local margin = self.opts.bar_hover_margin or 30
    
    -- Verificar que X está dentro del área de la barra
    local bar_start = self.opts.bar_margin_left
    local bar_end = self.state.w - self.opts.bar_margin_right
    local in_x_range = (x >= bar_start - 10) and (x <= bar_end + 10)
    
    -- Área sensible vertical: ±margin píxeles alrededor de la barra
    local in_y_range = (y >= bar_visual_y - margin) and (y <= bar_visual_y + margin)
    
    return in_x_range and in_y_range
end

function ProgressBar:get_seek_percentage(x)
    local bar_start = self.opts.bar_margin_left
    local bar_end = self.state.w - self.opts.bar_margin_right
    local bar_width = bar_end - bar_start
    local pct = (x - bar_start) / bar_width
    return math.max(0, math.min(1, pct))
end

function ProgressBar:handle_input(event, x, y)
    -- Update hovering state for draw
    local hovering = self:is_hovering(x, y)
    self.state.hovering_bar = hovering

    if event == "down" then
        if hovering then
            self.state.dragging = true
            mp.set_property("window-dragging", "no")
            self.state.visual_seek_pct = self:get_seek_percentage(x)
            return true
        end
    elseif event == "move" then
        if self.state.dragging then
            mp.set_property("window-dragging", "no")
            self.state.visual_seek_pct = self:get_seek_percentage(x)
            return true
        end
    elseif event == "up" then
        if self.state.dragging then
            if self.state.visual_seek_pct >= 0 then
                mp.commandv("seek", self.state.visual_seek_pct * 100, "absolute-percent+exact")
            end
            self.state.dragging = false
            self.state.visual_seek_pct = -1
            mp.set_property("window-dragging", "yes")
            return true
        end
    end
    return false
end

function ProgressBar:draw(ass)
    local w, h = self.state.w, self.state.h
    local opts = self.opts
    local state = self.state
    
    local bar_start = opts.bar_margin_left
    local bar_end = w - opts.bar_margin_right
    local bar_width = bar_end - bar_start
    
    local bar_h = (state.hovering_bar or state.dragging) and opts.bar_hover_height or opts.bar_height
    -- Fila superior para la barra
    local bar_y_pos = h - opts.bar_row_offset
    
    local progress = 0
    -- Prioridad a la visualización del arrastre sobre la posición real
    if state.visual_seek_pct and state.visual_seek_pct >= 0 then
        progress = state.visual_seek_pct
    elseif state.duration > 0 then
        progress = state.position / state.duration
    end
    
    -- Background Bar (con bordes redondeados)
    ass:new_event()
    ass:append(string.format("{\\bord0\\shad0\\c&H%s&\\alpha&H%s&}", "FFFFFF", "BB"))
    ass:pos(bar_start, bar_y_pos - bar_h/2)
    ass:draw_start()
    ass:round_rect_cw(0, 0, bar_width, bar_h, bar_h/2)
    ass:draw_stop()
    
    -- Progress Bar
    if progress > 0 then
        ass:new_event()
        ass:append(string.format("{\\bord0\\shad0\\c&H%s&\\alpha&H00&}", opts.color_played))
        ass:pos(bar_start, bar_y_pos - bar_h/2)
        ass:draw_start()
        ass:round_rect_cw(0, 0, bar_width * progress, bar_h, bar_h/2)
        ass:draw_stop()
        
        -- Handle (Círculo perfecto)
        if state.hovering_bar or state.dragging or (state.visual_seek_pct and state.visual_seek_pct >= 0) then
           local r = opts.handle_size / 2
           local cx = bar_start + bar_width * progress
           local cy = bar_y_pos
           
           ass:new_event()
           ass:append(string.format("{\\bord0\\shad0\\c&H%s&}", opts.color_played))
           ass:pos(cx, cy)
           ass:draw_start()
           -- Círculo perfecto usando bezier curves
           local k = 0.5522847498  -- Constante para aproximar círculo con bezier
           ass:move_to(0, -r)
           ass:bezier_curve(r*k, -r, r, -r*k, r, 0)
           ass:bezier_curve(r, r*k, r*k, r, 0, r)
           ass:bezier_curve(-r*k, r, -r, r*k, -r, 0)
           ass:bezier_curve(-r, -r*k, -r*k, -r, 0, -r)
           ass:draw_stop()
        end
    end
end

return ProgressBar