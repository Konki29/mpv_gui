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
        local icon_y = self.state.h - self.opts.controls_y_offset
        local icon_x = self.state.w / 2
        local hitbox = 25
        local box_top = self.state.h - self.opts.box_height
        
        if y >= box_top and math.abs(x - icon_x) < hitbox and math.abs(y - icon_y) < hitbox then
            mp.command("cycle pause")
            return true
        end
    end
    return false
end

function PlayButton:draw(ass)
    local icon_y = self.state.h - self.opts.controls_y_offset
    local cur_x = self.state.w / 2
    
    ass:new_event()
    ass:pos(cur_x, icon_y)
    ass:an(5)
    ass:append("{\\bord0\\shad0\\c&HFFFFFF&}")
    ass:draw_start()
    if self.state.paused then
        ass:move_to(-7, -10)
        ass:line_to(10, 0)
        ass:line_to(-7, 10)
    else
        ass:rect_cw(-7, -8, -3, 8)
        ass:rect_cw(3, -8, 7, 8)
    end
    ass:draw_stop()
end

return PlayButton
