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
    -- All controls share this Y baseline
    local cy = self.state.h - self.opts.controls_y_offset
    local spk_x = 30
    local slider_x = spk_x + 28
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
        -- Mute toggle
        if math.abs(x - spk_x) < 18 and math.abs(y - cy) < 18 then
            mp.commandv("cycle", "mute")
            return true
        end
        -- Slider click
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

    -- ── Speaker icon ──
    ass:new_event()
    ass:pos(spk_x, cy)
    ass:an(5)
    local ic = muted and "555555" or "FFFFFF"
    ass:append(string.format("{\\bord0\\shad0\\c&H%s&}", ic))
    ass:draw_start()
    -- body rectangle
    ass:rect_cw(-5, -4, 1, 4)
    -- cone triangle
    ass:move_to(1, -4)
    ass:line_to(7, -8)
    ass:line_to(7, 8)
    ass:line_to(1, 4)
    ass:line_to(1, -4)
    ass:draw_stop()

    if muted then
        -- Red X
        ass:new_event()
        ass:pos(spk_x + 12, cy)
        ass:an(5)
        ass:append("{\\fnSegoe UI\\fs14\\bord1\\shad0\\1c&H3333FF&\\3c&H000000&}")
        ass:append("✕")
    end

    -- ── Slider track (gray background) ──
    local th = 4     -- track height
    local ty = cy - th / 2
    ass:new_event()
    ass:pos(slider_x, ty)
    ass:an(7)
    ass:append("{\\bord0\\shad0\\c&H555555&}")
    ass:draw_start()
    ass:round_rect_cw(0, 0, slider_w, th, th / 2)
    ass:draw_stop()

    -- ── Filled portion (white / gray if muted) ──
    local fw = slider_w * pct
    if fw > 1 then
        ass:new_event()
        ass:pos(slider_x, ty)
        ass:an(7)
        ass:append(string.format("{\\bord0\\shad0\\c&H%s&}", muted and "666666" or "FFFFFF"))
        ass:draw_start()
        ass:round_rect_cw(0, 0, fw, th, th / 2)
        ass:draw_stop()
    end

    -- ── Handle dot ──
    local hx = slider_x + fw
    local hr = self.dragging_vol and 7 or 5
    ass:new_event()
    ass:pos(hx, cy)
    ass:an(5)
    ass:append(string.format("{\\bord0\\shad0\\c&H%s&}", muted and "666666" or "FFFFFF"))
    ass:draw_start()
    -- circle via bezier
    local k = 0.5522847498
    ass:move_to(0, -hr)
    ass:bezier_curve(hr*k, -hr, hr, -hr*k, hr, 0)
    ass:bezier_curve(hr, hr*k, hr*k, hr, 0, hr)
    ass:bezier_curve(-hr*k, hr, -hr, hr*k, -hr, 0)
    ass:bezier_curve(-hr, -hr*k, -hr*k, -hr, 0, -hr)
    ass:draw_stop()

    -- ── Percentage text ──
    ass:new_event()
    ass:pos(slider_x + slider_w + 12, cy)
    ass:an(4)
    ass:append(string.format(
        "{\\fnSegoe UI\\fs13\\bord1\\shad0\\1c&H%s&\\3c&H000000&}",
        muted and "555555" or "CCCCCC"))
    ass:append(string.format("%d%%", math.floor(vol)))
end

return VolumeButton
