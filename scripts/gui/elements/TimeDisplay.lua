local Element = require 'gui.elements.Element'
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
    local icon_y = self.state.h - self.opts.box_height / 2
    local cur_x = 20 + 40 -- Offset from PlayButton
    
    ass:new_event()
    ass:pos(cur_x, icon_y)
    ass:an(4)
    ass:append(string.format("{\\fs%d\\bord1\\shad0\\1c&HFFFFFF&\\3c&H000000&}", self.opts.font_size))
    
    local time_to_show = self.state.position
    if self.state.visual_seek_pct and self.state.visual_seek_pct >= 0 then
        time_to_show = self.state.visual_seek_pct * self.state.duration
    end
    
    ass:append(timestamp(time_to_show) .. " / " .. timestamp(self.state.duration))
end

return TimeDisplay
