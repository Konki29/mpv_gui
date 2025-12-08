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
        -- Hitbox específico para el botón Play/Pause
        local icon_y = self.state.h - self.opts.box_height / 2
        local icon_x = 20
        local hitbox_radius = 25 -- Área de clic generosa pero específica
        
        -- También verificar que estamos en el área del control box (Y)
        local box_top = self.state.h - self.opts.box_height
        
        if y >= box_top and x <= (icon_x + hitbox_radius) and math.abs(y - icon_y) < hitbox_radius then
            mp.command("cycle pause")
            return true -- Consumir el evento
        end
    end
    return false
end

function PlayButton:draw(ass)
    local icon_y = self.state.h - self.opts.box_height / 2
    local cur_x = 20
    
    ass:new_event()
    ass:pos(cur_x, icon_y)
    ass:append("{\\bord0\\shad0\\c&HFFFFFF&}")
    ass:draw_start()
    if self.state.paused then
        ass:move_to(0, -10)
        ass:line_to(15, 0)
        ass:line_to(0, 10)
    else
        ass:rect_cw(0, -10, 5, 10)
        ass:rect_cw(10, -10, 15, 10)
    end
    ass:draw_stop()
end

return PlayButton
