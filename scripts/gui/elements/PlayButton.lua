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
        -- Hitbox específico para el botón Play/Pause (centrado)
        local icon_y = self.state.h - self.opts.controls_row_offset
        local icon_x = self.state.w / 2  -- Centrado
        local hitbox_radius = 30
        
        -- Verificar que estamos en el área del control box (Y)
        local box_top = self.state.h - self.opts.box_height
        
        if y >= box_top and math.abs(x - icon_x) < hitbox_radius and math.abs(y - icon_y) < hitbox_radius then
            mp.command("cycle pause")
            return true
        end
    end
    return false
end

function PlayButton:draw(ass)
    -- Fila inferior para controles, centrado horizontalmente
    local icon_y = self.state.h - self.opts.controls_row_offset
    local cur_x = self.state.w / 2  -- Centrado
    
    ass:new_event()
    ass:pos(cur_x, icon_y)
    ass:an(5) -- Anchor center
    ass:append("{\\bord0\\shad0\\c&HFFFFFF&}")
    ass:draw_start()
    if self.state.paused then
        -- Triángulo de play centrado
        ass:move_to(-8, -12)
        ass:line_to(12, 0)
        ass:line_to(-8, 12)
    else
        -- Pause centrado
        ass:rect_cw(-8, -10, -3, 10)
        ass:rect_cw(3, -10, 8, 10)
    end
    ass:draw_stop()
end

return PlayButton
