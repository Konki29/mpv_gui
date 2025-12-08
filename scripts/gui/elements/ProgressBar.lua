local mp = require 'mp'
local Element = require 'elements.Element'
local ProgressBar = setmetatable({}, {__index = Element})
ProgressBar.__index = ProgressBar

function ProgressBar.new(state, opts)
    local self = Element.new(state, opts)
    return setmetatable(self, ProgressBar)
end

function ProgressBar:is_hovering(y)
    local bar_top = self.state.h - self.opts.box_height - 10
    local bar_bottom = self.state.h - self.opts.box_height + self.opts.bar_hover_height + 10
    return (y >= bar_top and y <= bar_bottom)
end

function ProgressBar:get_seek_percentage(x)
    local pct = x / self.state.w
    return math.max(0, math.min(1, pct))
end

function ProgressBar:handle_input(event, x, y)
    -- Update hovering state for draw
    self.state.hovering_bar = self:is_hovering(y)

    if event == "down" then
        if self:is_hovering(y) then
            self.state.dragging = true
            mp.set_property("window-dragging", "no")
            self.state.visual_seek_pct = self:get_seek_percentage(x)
            return true -- Consumed
        end
    elseif event == "move" then
        if self.state.dragging then
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
    
    local bar_h = (state.hovering_bar or state.dragging) and opts.bar_hover_height or opts.bar_height
    local bar_y_pos = h - opts.box_height + ((state.hovering_bar or state.dragging) and -2 or 0)
    
    local progress = 0
    if state.visual_seek_pct and state.visual_seek_pct >= 0 then
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
    
    -- Progress Bar
    if progress > 0 then
        ass:new_event()
        ass:append(string.format("{\\bord0\\shad0\\c&H%s&\\alpha&H00&}", opts.color_played))
        ass:pos(0, bar_y_pos)
        ass:draw_start()
        ass:rect_cw(0, 0, w * progress, bar_h)
        ass:draw_stop()
        
        -- Handle (Circle)
        if state.hovering_bar or state.dragging or (state.visual_seek_pct and state.visual_seek_pct >= 0) then
           ass:new_event()
           ass:append(string.format("{\\bord0\\shad0\\c&H%s&}", opts.color_played))
           ass:pos(w * progress, bar_y_pos + bar_h/2)
           ass:draw_start()
           ass:round_rect_cw(-opts.handle_size/2, -opts.handle_size/2, opts.handle_size/2, opts.handle_size/2, opts.handle_size/4)
           ass:draw_stop()
        end
    end
end

return ProgressBar
