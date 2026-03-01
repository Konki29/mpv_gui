local Element = require 'elements.Element'
local TimeDisplay = setmetatable({}, {__index = Element})
TimeDisplay.__index = TimeDisplay

function TimeDisplay.new(state, opts)
    local self = Element.new(state, opts)
    return setmetatable(self, TimeDisplay)
end

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

function TimeDisplay:draw(ass)
    local cy = self.state.h - self.opts.controls_y_offset

    ass:new_event()
    ass:pos(self.state.w - 85, cy)
    ass:an(6)  -- middle-right anchor → vertically centered at cy
    ass:append(string.format(
        "{\\fn%s\\fs%d\\bord1\\shad0\\1c&HFFFFFF&\\3c&H000000&}",
        self.opts.font, self.opts.font_size))

    local t = self.state.position
    if self.state.visual_seek_pct and self.state.visual_seek_pct >= 0 then
        t = self.state.visual_seek_pct * self.state.duration
    end
    ass:append(timestamp(t) .. " / " .. timestamp(self.state.duration))
end

return TimeDisplay
