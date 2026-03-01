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
        if y >= self.state.h - self.opts.box_height
           and math.abs(x - cx) < 25 and math.abs(y - cy) < 25 then
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
    ass:pos(0, 0)
    ass:an(7)
    ass:append("{\\bord0\\shad0\\c&HFFFFFF&}")
    ass:draw_start()
    if self.state.paused then
        -- Play triangle (absolute coords centered on cx, cy)
        ass:move_to(cx - 7, cy - 10)
        ass:line_to(cx + 11, cy)
        ass:line_to(cx - 7, cy + 10)
    else
        -- Pause bars
        ass:rect_cw(cx - 8, cy - 9, cx - 3, cy + 9)
        ass:rect_cw(cx + 3, cy - 9, cx + 8, cy + 9)
    end
    ass:draw_stop()
end

return PlayButton
