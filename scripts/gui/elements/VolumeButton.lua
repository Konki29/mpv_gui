local mp = require 'mp'
local Element = require 'elements.Element'
local VolumeButton = setmetatable({}, {__index = Element})
VolumeButton.__index = VolumeButton

function VolumeButton.new(state, opts)
    local self = Element.new(state, opts)
    self.dragging_vol = false
    self.last_vol_seek = nil
    return setmetatable(self, VolumeButton)
end

function VolumeButton:_layout()
    local cy = self.state.h - self.opts.controls_y_offset
    local spk_x = 30
    local slider_x = spk_x + 30
    local slider_w = self.opts.volume_slider_width
    return cy, spk_x, slider_x, slider_w
end

function VolumeButton:_vol_from_x(x)
    local _, _, sx, sw = self:_layout()
    return math.max(0, math.min(100, ((x - sx) / sw) * 100))
end

function VolumeButton:handle_input(event, x, y)
    local cy, spk_x, slider_x, slider_w = self:_layout()
    local box_top = self.state.h - self.opts.box_height

    if event == "down" then
        if y < box_top then return false end
        if math.abs(x - spk_x) < 18 and math.abs(y - cy) < 18 then
            mp.commandv("cycle", "mute")
            return true
        end
        if x >= slider_x - 8 and x <= slider_x + slider_w + 8
           and math.abs(y - cy) < 18 then
            self.dragging_vol = true
            local v = self:_vol_from_x(x)
            mp.command(string.format("no-osd set volume %d", math.floor(v)))
            self.last_vol_seek = v
            return true
        end
    elseif event == "move" then
        if self.dragging_vol then
            local v = self:_vol_from_x(x)
            if not self.last_vol_seek or math.abs(v - self.last_vol_seek) > 0.5 then
                mp.command(string.format("no-osd set volume %d", math.floor(v)))
                self.last_vol_seek = v
            end
            return true
        end
    elseif event == "up" then
        if self.dragging_vol then
            self.dragging_vol = false
            self.last_vol_seek = nil
            return true
        end
    end
    return false
end

function VolumeButton:draw(ass)
    local cy, spk_x, slider_x, slider_w = self:_layout()
    local vol = math.max(0, math.min(100, self.state.volume or 100))
    local muted = self.state.muted or false
    local pct = vol / 100
    local font = self.opts.font

    -- Definición de colores (Formato ASS: BGR -> Azul, Verde, Rojo)
    local color_bg = "555555"      -- Gris oscuro para el fondo
    local color_normal = "FFFFFF"  -- Blanco para el volumen normal
    local color_active = "FF8800"  -- Celeste/Azul claro para cuando arrastras
    local color_muted = "666666"   -- Gris medio para el estado silenciado

    -- Determinar el color actual de la barra izquierda y el círculo
    local current_color = color_normal
    if muted then
        current_color = color_muted
    elseif self.dragging_vol then
        current_color = color_active
    end

    -- Icono del altavoz
    ass:new_event()
    ass:pos(spk_x, cy)
    ass:an(5)
    ass:append(string.format("{\\bord0\\shad0\\c&H%s&}", muted and "555555" or "FFFFFF"))
    ass:draw_start()
    ass:rect_cw(-5, -5, 1, 5)
    ass:move_to(1, -5)
    ass:line_to(8, -9)
    ass:line_to(8, 9)
    ass:line_to(1, 5)
    ass:line_to(1, -5)
    ass:draw_stop()

    if muted then
        ass:new_event()
        ass:pos(spk_x + 14, cy)
        ass:an(5)
        ass:append(string.format("{\\fn%s\\fs14\\bord1\\shad0\\1c&H3333FF&\\3c&H000000&}", font))
        ass:append("✕")
    end

    -- Cálculos exactos para centrar la barra en el eje Y
    local th = 4
    local y_top = cy - (th / 2)
    local y_bottom = cy + (th / 2)

    -- Barra de fondo (la parte grisácea derecha)
    ass:new_event()
    ass:pos(0, 0)
    ass:an(7) -- Usamos alineación superior izquierda y coordenadas absolutas
    ass:append(string.format("{\\bord0\\shad0\\c&H%s&}", color_bg))
    ass:draw_start()
    ass:round_rect_cw(slider_x, y_top, slider_x + slider_w, y_bottom, th / 2)
    ass:draw_stop()

    -- Barra rellena (la parte izquierda que indica el nivel)
    local fw = slider_w * pct
    if fw > 0 then
        ass:new_event()
        ass:pos(0, 0)
        ass:an(7)
        ass:append(string.format("{\\bord0\\shad0\\c&H%s&}", current_color))
        ass:draw_start()
        ass:round_rect_cw(slider_x, y_top, slider_x + fw, y_bottom, th / 2)
        ass:draw_stop()
    end

    -- Círculo separador (Handle)
    local hx = slider_x + fw
    local hr = self.dragging_vol and 7 or 5
    ass:new_event()
    ass:pos(hx, cy)
    ass:an(5) -- an(5) es perfecto aquí porque la forma se dibuja alrededor de 0,0
    ass:append(string.format("{\\bord0\\shad0\\c&H%s&}", current_color))
    ass:draw_start()
    local k = 0.5522847498
    ass:move_to(0, -hr)
    ass:bezier_curve(hr*k, -hr, hr, -hr*k, hr, 0)
    ass:bezier_curve(hr, hr*k, hr*k, hr, 0, hr)
    ass:bezier_curve(-hr*k, hr, -hr, hr*k, -hr, 0)
    ass:bezier_curve(-hr, -hr*k, -hr*k, -hr, 0, -hr)
    ass:draw_stop()

    -- Porcentaje de volumen
    ass:new_event()
    ass:pos(slider_x + slider_w + 12, cy)
    ass:an(4)
    ass:append(string.format(
        "{\\fn%s\\fs13\\bord1\\shad0\\1c&H%s&\\3c&H000000&}",
        font, muted and "555555" or "CCCCCC"))
    ass:append(string.format("%d%%", math.floor(vol)))
end

return VolumeButton
