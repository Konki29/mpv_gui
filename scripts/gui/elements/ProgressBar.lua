local mp = require 'mp'
local Element = require 'elements.Element'
local ProgressBar = setmetatable({}, {__index = Element})
ProgressBar.__index = ProgressBar

function ProgressBar.new(state, opts)
    local self = Element.new(state, opts)
    self.last_seek = nil
    return setmetatable(self, ProgressBar)
end

function ProgressBar:is_hovering(x, y)
    local bar_y = self.state.h - self.opts.bar_y_offset
    local margin = self.opts.bar_hover_margin
    local bar_start = self.opts.bar_margin_left
    local bar_end = self.state.w - self.opts.bar_margin_right
    
    local in_x = (x >= bar_start - 10) and (x <= bar_end + 10)
    local in_y = (y >= bar_y - margin) and (y <= bar_y + margin)
    return in_x and in_y
end

function ProgressBar:get_seek_percentage(x)
    local bar_start = self.opts.bar_margin_left
    local bar_end = self.state.w - self.opts.bar_margin_right
    local bar_width = bar_end - bar_start
    local pct = (x - bar_start) / bar_width
    return math.max(0, math.min(1, pct))
end

function ProgressBar:handle_input(event, x, y)
    if event == "down" then
        if self:is_hovering(x, y) then
            -- Lock: start drag and seek immediately (mpv-osc-modern pattern)
            self.state.dragging = true
            self.state.hovering_bar = true
            local pct = self:get_seek_percentage(x)
            self.state.visual_seek_pct = pct
            -- Seek immediately on click
            mp.commandv("seek", pct * 100, "absolute-percent+exact")
            self.last_seek = pct
            return true
        end
        
    elseif event == "move" then
        if self.state.dragging then
            -- During drag: always update, regardless of hover position
            -- (active-element locking — mouse can go anywhere)
            local pct = self:get_seek_percentage(x)
            self.state.visual_seek_pct = pct
            -- Seek while dragging (deduplicate identical seeks)
            if self.last_seek == nil or math.abs(pct - self.last_seek) > 0.001 then
                mp.commandv("seek", pct * 100, "absolute-percent+exact")
                self.last_seek = pct
            end
            return true
        else
            -- Not dragging: just update hover state
            self.state.hovering_bar = self:is_hovering(x, y)
        end
        
    elseif event == "up" then
        if self.state.dragging then
            self.state.dragging = false
            self.state.visual_seek_pct = -1
            self.last_seek = nil
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
    local bar_y = h - opts.bar_y_offset
    
    local progress = 0
    if state.visual_seek_pct and state.visual_seek_pct >= 0 then
        progress = state.visual_seek_pct
    elseif state.duration > 0 then
        progress = state.position / state.duration
    end
    
    -- Background track
    ass:new_event()
    ass:append(string.format("{\\bord0\\shad0\\c&H%s&\\alpha&H%s&}", "FFFFFF", "BB"))
    ass:pos(bar_start, bar_y - bar_h/2)
    ass:draw_start()
    ass:round_rect_cw(0, 0, bar_width, bar_h, bar_h/2)
    ass:draw_stop()
    
    -- Played portion
    if progress > 0 then
        ass:new_event()
        ass:append(string.format("{\\bord0\\shad0\\c&H%s&\\alpha&H00&}", opts.color_played))
        ass:pos(bar_start, bar_y - bar_h/2)
        ass:draw_start()
        ass:round_rect_cw(0, 0, bar_width * progress, bar_h, bar_h/2)
        ass:draw_stop()
        
        -- Handle circle (visible on hover/drag)
        if state.hovering_bar or state.dragging then
           local r = opts.handle_size / 2
           local cx = bar_start + bar_width * progress
           local cy = bar_y
           
           ass:new_event()
           ass:append(string.format("{\\bord0\\shad0\\c&H%s&}", opts.color_played))
           ass:pos(cx, cy)
           ass:draw_start()
           local k = 0.5522847498
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