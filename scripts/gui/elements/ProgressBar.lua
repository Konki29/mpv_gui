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
    return (x >= bar_start - 10) and (x <= bar_end + 10)
       and (y >= bar_y - margin) and (y <= bar_y + margin)
end

function ProgressBar:get_seek_percentage(x)
    local bar_start = self.opts.bar_margin_left
    local bar_end = self.state.w - self.opts.bar_margin_right
    return math.max(0, math.min(1, (x - bar_start) / (bar_end - bar_start)))
end

function ProgressBar:handle_input(event, x, y)
    if event == "down" then
        if self:is_hovering(x, y) then
            self.state.dragging = true
            self.state.hovering_bar = true
            local pct = self:get_seek_percentage(x)
            self.state.visual_seek_pct = pct
            mp.commandv("seek", pct * 100, "absolute-percent+exact")
            self.last_seek = pct
            return true
        end
    elseif event == "move" then
        if self.state.dragging then
            local pct = self:get_seek_percentage(x)
            self.state.visual_seek_pct = pct
            if self.last_seek == nil or math.abs(pct - self.last_seek) > 0.001 then
                mp.commandv("seek", pct * 100, "absolute-percent+exact")
                self.last_seek = pct
            end
            return true
        else
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

-- Helper: draw a circle at absolute (cx, cy) with radius r
local function draw_circle(ass, cx, cy, r, color)
    ass:new_event()
    ass:pos(0, 0)
    ass:an(7)
    ass:append(string.format("{\\bord0\\shad0\\c&H%s&}", color))
    ass:draw_start()
    local k = 0.5522847498
    ass:move_to(cx, cy - r)
    ass:bezier_curve(cx + r*k, cy - r, cx + r, cy - r*k, cx + r, cy)
    ass:bezier_curve(cx + r, cy + r*k, cx + r*k, cy + r, cx, cy + r)
    ass:bezier_curve(cx - r*k, cy + r, cx - r, cy + r*k, cx - r, cy)
    ass:bezier_curve(cx - r, cy - r*k, cx - r*k, cy - r, cx, cy - r)
    ass:draw_stop()
end

function ProgressBar:draw(ass)
    local w, h = self.state.w, self.state.h
    local o = self.opts
    local s = self.state
    
    local bar_start = o.bar_margin_left
    local bar_end = w - o.bar_margin_right
    local bar_width = bar_end - bar_start
    local bar_h = (s.hovering_bar or s.dragging) and o.bar_hover_height or o.bar_height
    local bar_y = h - o.bar_y_offset
    local top = bar_y - bar_h / 2
    
    local progress = 0
    if s.visual_seek_pct and s.visual_seek_pct >= 0 then
        progress = s.visual_seek_pct
    elseif s.duration > 0 then
        progress = s.position / s.duration
    end
    
    -- Background track (absolute coords)
    ass:new_event()
    ass:pos(0, 0)
    ass:an(7)
    ass:append(string.format("{\\bord0\\shad0\\c&HFFFFFF&\\alpha&HBB&}"))
    ass:draw_start()
    ass:round_rect_cw(bar_start, top, bar_end, top + bar_h, bar_h / 2)
    ass:draw_stop()
    
    -- Played portion
    if progress > 0 then
        local filled_end = bar_start + bar_width * progress
        ass:new_event()
        ass:pos(0, 0)
        ass:an(7)
        ass:append(string.format("{\\bord0\\shad0\\c&H%s&\\alpha&H00&}", o.color_played))
        ass:draw_start()
        ass:round_rect_cw(bar_start, top, filled_end, top + bar_h, bar_h / 2)
        ass:draw_stop()
        
        -- Handle circle
        if s.hovering_bar or s.dragging then
            draw_circle(ass, filled_end, bar_y, o.handle_size / 2, o.color_played)
        end
    end
end

return ProgressBar