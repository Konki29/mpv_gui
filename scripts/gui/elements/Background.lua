local Element = require 'elements.Element'
local Background = setmetatable({}, {__index = Element})
Background.__index = Background

function Background.new(state, opts)
    local self = Element.new(state, opts)
    return setmetatable(self, Background)
end

function Background:draw(ass)
    local w, h = self.state.w, self.state.h
    ass:new_event()
    ass:append("{\\pos(0,0)\\r\\shad0\\bord0\\an7}")
    ass:append("{\\c&H000000&\\alpha&H40&}")
    ass:draw_start()
    ass:rect_cw(0, h - self.opts.box_height, w, h)
    ass:draw_stop()
end

return Background
