local mp = require 'mp' -- Necesario para controlar window-dragging
local Element = require 'elements.Element'
local Background = setmetatable({}, {__index = Element})
Background.__index = Background

function Background.new(state, opts)
    local self = Element.new(state, opts)
    return setmetatable(self, Background)
end

function Background:draw(ass)
    local w, h = self.state.w, self.state.h
    local box_height = self.opts.box_height
    
    -- Gradiente profesional: 1 franja por cada 2 pixels para máxima suavidad
    -- sin sacrificar demasiado rendimiento
    local pixel_step = 2
    local num_strips = math.floor(box_height / pixel_step)
    
    -- Opacidad: 00 = opaco, FF = transparente
    local alpha_bottom = 0x20  -- Más oscuro abajo
    local alpha_top = 0xFF     -- Transparente arriba
    
    for i = 0, num_strips - 1 do
        -- t va de 0 (abajo) a 1 (arriba)
        local t = i / num_strips
        
        -- Curva ease-out cuadrática: más cambio al principio, suave al final
        -- Esto hace que el gradiente se desvanezca de forma más natural
        local eased_t = 1 - (1 - t) * (1 - t)
        
        local alpha = math.floor(alpha_bottom + (alpha_top - alpha_bottom) * eased_t)
        local alpha_hex = string.format("%02X", alpha)
        
        -- Posición: desde abajo hacia arriba
        local strip_bottom = h - (i * pixel_step)
        local strip_top = strip_bottom - pixel_step
        
        ass:new_event()
        ass:append("{\\pos(0,0)\\r\\shad0\\bord0\\an7}")
        ass:append("{\\c&H000000&\\alpha&H" .. alpha_hex .. "&}")
        ass:draw_start()
        ass:rect_cw(0, strip_top, w, strip_bottom)
        ass:draw_stop()
    end
end

-- Manejar input para bloquear el arrastre de ventana PREVENTIVAMENTE
function Background:handle_input(event, x, y)
    local box_top = self.state.h - self.opts.box_height
    local in_control_area = y >= box_top
    
    -- PREVENTIVO: Bloquear window-dragging cuando entramos al área de controles
    if event == "move" then
        if in_control_area then
            if not self.state.control_area_active then
                self.state.control_area_active = true
                mp.set_property("window-dragging", "no")
            end
        else
            -- Solo restaurar si no hay ningún arrastre activo
            if self.state.control_area_active and not self.state.dragging and not self.state.bg_dragging then
                self.state.control_area_active = false
                mp.set_property("window-dragging", "yes")
            end
        end
        -- NO consumir move, para que otros elementos puedan actualizar hover
        return false
    end
    
    -- Para down/up solo actuamos si estamos en el área
    if event == "down" and in_control_area then
        self.state.bg_dragging = true
        mp.set_property("window-dragging", "no")
        -- NO consumir el evento para que otros elementos (PlayButton, etc) puedan procesarlo
        return false
    end
    
    if event == "up" then
        if self.state.bg_dragging then
            self.state.bg_dragging = false
            -- Restaurar solo si no estamos en el área y no hay otro arrastre
            if not in_control_area and not self.state.dragging then
                mp.set_property("window-dragging", "yes")
            end
        end
        return false
    end

    return false
end

return Background