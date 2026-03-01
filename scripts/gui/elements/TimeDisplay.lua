local mp = require 'mp'
local Element = require 'elements.Element'
local TimeDisplay = setmetatable({}, {__index = Element})
TimeDisplay.__index = TimeDisplay

function TimeDisplay.new(state, opts)
    local self = Element.new(state, opts)
    self.show_remaining = false  -- toggle: false=elapsed, true=remaining
    return setmetatable(self, TimeDisplay)
end

local function timestamp(seconds)
    if not seconds or seconds < 0 then return "0:00" end
    local hrs = math.floor(seconds / 3600)
    local min = math.floor((seconds % 3600) / 60)
    local sec = math.floor(seconds % 60)
    if hrs > 0 then
        return string.format("%d:%02d:%02d", hrs, min, sec)
    else
        return string.format("%d:%02d", min, sec)
    end
end

function TimeDisplay:handle_input(event, x, y)
    if event == "down" then
        local cy = self.state.h - self.opts.controls_y_offset
        -- Hitbox: right side of the control bar
        if x >= self.state.w - 180 and x <= self.state.w - 60
           and math.abs(y - cy) < 18 then
            self.show_remaining = not self.show_remaining
            return true
        end
    end
    return false
end

function TimeDisplay:draw(ass)
    local cy = self.state.h - self.opts.controls_y_offset

    ass:new_event()
    ass:pos(self.state.w - 90, cy)
    ass:an(6)
    ass:append(string.format(
        "{\\fn%s\\fs%d\\bord1\\shad0\\1c&HFFFFFF&\\3c&H000000&}",
        self.opts.font, self.opts.font_size))

    local dur = self.state.duration or 0
    local pos = self.state.position or 0
    if self.state.visual_seek_pct and self.state.visual_seek_pct >= 0 then
        pos = self.state.visual_seek_pct * dur
    end

    if self.show_remaining then
        local remaining = math.max(0, dur - pos)
        ass:append("-" .. timestamp(remaining) .. " / " .. timestamp(dur))
    else
        ass:append(timestamp(pos) .. " / " .. timestamp(dur))
    end
end

return TimeDisplay
