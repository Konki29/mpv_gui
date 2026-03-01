local mp = require 'mp'
local Element = require 'elements.Element'
local PlayButton = setmetatable({}, {__index = Element})
PlayButton.__index = PlayButton

function PlayButton.new(state, opts)
    local self = Element.new(state, opts)
    return setmetatable(self, PlayButton)
end

function PlayButton:handle_input(event, x, y)
    if event == "down" then
        local cy = self.state.h - self.opts.controls_y_offset
        local cx = self.state.w / 2
        local box_top = self.state.h - self.opts.box_height
        if y >= box_top and math.abs(x - cx) < 25 and math.abs(y - cy) < 25 then
            mp.command("cycle pause")
            return true
        end
    end
    return false
end

function PlayButton:draw(ass)
    local cy = self.state.h - self.opts.controls_y_offset
    local cx = self.state.w / 2

    ass:new_event()
    ass:pos(cx, cy)
    ass:an(5)
    ass:append("{\\bord0\\shad0\\c&HFFFFFF&}")
    ass:draw_start()
    if self.state.paused then
        -- Solid Play triangle
        ass:move_to(-7, -10)
        ass:line_to(11, 0)
        ass:line_to(-7, 10)
    else
        -- Solid Pause bars
        ass:rect_cw(-8, -9, -3, 9)
        ass:rect_cw(3, -9, 8, 9)
    end
    ass:draw_stop()
end

return PlayButton
