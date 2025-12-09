local mp = require 'mp'
local Element = require 'elements.Element'
local DropZone = setmetatable({}, {__index = Element})
DropZone.__index = DropZone

function DropZone.new(state, opts)
    local self = Element.new(state, opts)
    return setmetatable(self, DropZone)
end

function DropZone:draw(ass)
    -- Solo mostrar si no hay archivo cargado
    if self.state.has_file then
        return
    end
    
    local w, h = self.state.w, self.state.h
    local cx, cy = w / 2, h / 2
    
    -- Fondo oscuro semi-transparente para todo el área
    ass:new_event()
    ass:append("{\\pos(0,0)\\r\\shad0\\bord0\\an7}")
    ass:append("{\\c&H1a1a1a&\\alpha&H20&}")
    ass:draw_start()
    ass:rect_cw(0, 0, w, h)
    ass:draw_stop()
    
    -- Icono de archivo/carpeta (simple rectángulo con esquina doblada)
    local icon_size = 60
    local icon_x = cx - icon_size / 2
    local icon_y = cy - 80
    
    ass:new_event()
    ass:append("{\\pos(0,0)\\r\\shad0\\bord0\\an7}")
    ass:append("{\\c&H808080&\\alpha&H00&}")
    ass:draw_start()
    -- Rectángulo principal del icono
    ass:rect_cw(icon_x, icon_y, icon_x + icon_size, icon_y + icon_size * 1.2)
    ass:draw_stop()
    
    -- Esquina doblada
    ass:new_event()
    ass:append("{\\pos(0,0)\\r\\shad0\\bord0\\an7}")
    ass:append("{\\c&H606060&\\alpha&H00&}")
    ass:draw_start()
    local fold = 15
    ass:move_to(icon_x + icon_size - fold, icon_y)
    ass:line_to(icon_x + icon_size, icon_y + fold)
    ass:line_to(icon_x + icon_size - fold, icon_y + fold)
    ass:line_to(icon_x + icon_size - fold, icon_y)
    ass:draw_stop()
    
    -- Símbolo de play dentro del icono
    ass:new_event()
    ass:append("{\\pos(0,0)\\r\\shad0\\bord0\\an7}")
    ass:append("{\\c&HFFFFFF&\\alpha&H00&}")
    ass:draw_start()
    local play_cx = icon_x + icon_size / 2
    local play_cy = icon_y + icon_size * 0.6
    local play_size = 15
    ass:move_to(play_cx - play_size * 0.4, play_cy - play_size * 0.6)
    ass:line_to(play_cx + play_size * 0.6, play_cy)
    ass:line_to(play_cx - play_size * 0.4, play_cy + play_size * 0.6)
    ass:line_to(play_cx - play_size * 0.4, play_cy - play_size * 0.6)
    ass:draw_stop()
    
    -- Texto principal "Drop file here"
    ass:new_event()
    ass:append(string.format("{\\pos(%d,%d)\\an5\\r\\bord0\\shad0}", cx, cy + 30))
    ass:append("{\\fnSegoe UI\\fs24\\c&HFFFFFF&\\alpha&H20&}")
    ass:append("Drop a file here to play")
    
    -- Texto secundario con teclas de acceso rápido
    ass:new_event()
    ass:append(string.format("{\\pos(%d,%d)\\an5\\r\\bord0\\shad0}", cx, cy + 65))
    ass:append("{\\fnSegoe UI\\fs14\\c&H888888&\\alpha&H20&}")
    ass:append("or press Ctrl+O to open")
end

function DropZone:handle_input(event, x, y)
    -- Si no hay archivo, podríamos abrir un diálogo al hacer click
    if not self.state.has_file and event == "down" then
        -- Tu script actual parece no tener un file picker, pero podemos añadir la funcionalidad
        -- Por ahora, solo consumimos el click para evitar comportamiento no deseado
        return true
    end
    return false
end

return DropZone
