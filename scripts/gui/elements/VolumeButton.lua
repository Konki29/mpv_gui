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

-- Helper: draw circle at absolute position
local function draw_circle_abs(ass, cx, cy, r, color)
    ass:new_event()
    ass:pos(0, 0)
    ass:an(7)
    ass:append(string.format("{\\bord0\\shad0\\c&H%s&}", color))
    ass:draw_start()
    local k = 0.5522847498
    ass:move_to(cx, cy - r)
    ass:bezier_curve(cx + r*k, cy - r, cx + r, cy - r*k, cx + r, cy)
    ass:bezier_curve(cx + r, cy + r*k, cx + r*k, cy + r, cx, cy + r)
    ass:bezier_curve(cx - r*k, cy + r, cx - r, cy + r*k, cx - r, cy)
    ass:bezier_curve(cx - r, cy - r*k, cx - r*k, cy - r, cx, cy - r)
    ass:draw_stop()
end

function VolumeButton:draw(ass)
    local cy, spk_x, slider_x, slider_w = self:_layout()
    local vol = math.max(0, math.min(100, self.state.volume or 100))
    local muted = self.state.muted or false
    local pct = vol / 100
    local font = self.opts.font

    -- Color logic
    local ic = muted and "555555" or "FFFFFF"
    local fill_col = muted and "666666" or (self.dragging_vol and "FF8800" or "FFFFFF")
    local bg_col = "555555"

    -- Speaker icon (absolute coords)
    ass:new_event()
    ass:pos(0, 0)
    ass:an(7)
    ass:append(string.format("{\\bord0\\shad0\\c&H%s&}", ic))
    ass:draw_start()
    -- Body
    ass:rect_cw(spk_x - 5, cy - 5, spk_x + 1, cy + 5)
    -- Cone
    ass:move_to(spk_x + 1, cy - 5)
    ass:line_to(spk_x + 8, cy - 9)
    ass:line_to(spk_x + 8, cy + 9)
    ass:line_to(spk_x + 1, cy + 5)
    ass:line_to(spk_x + 1, cy - 5)
    ass:draw_stop()

    -- Mute X
    if muted then
        ass:new_event()
        ass:pos(spk_x + 14, cy)
        ass:an(5)
        ass:append(string.format("{\\fn%s\\fs14\\bord1\\shad0\\1c&H3333FF&\\3c&H000000&}", font))
        ass:append("✕")
    end

    -- Slider track (absolute coords, perfectly centered on cy)
    local th = 4
    local y_top = cy - th / 2
    local y_bot = cy + th / 2
    ass:new_event()
    ass:pos(0, 0)
    ass:an(7)
    ass:append(string.format("{\\bord0\\shad0\\c&H%s&}", bg_col))
    ass:draw_start()
    ass:round_rect_cw(slider_x, y_top, slider_x + slider_w, y_bot, th / 2)
    ass:draw_stop()

    -- Filled portion
    local fw = slider_w * pct
    if fw > 0 then
        ass:new_event()
        ass:pos(0, 0)
        ass:an(7)
        ass:append(string.format("{\\bord0\\shad0\\c&H%s&}", fill_col))
        ass:draw_start()
        ass:round_rect_cw(slider_x, y_top, slider_x + fw, y_bot, th / 2)
        ass:draw_stop()
    end

    -- Handle circle (absolute)
    local hx = slider_x + fw
    local hr = self.dragging_vol and 7 or 5
    draw_circle_abs(ass, hx, cy, hr, fill_col)

    -- Volume percentage text
    ass:new_event()
    ass:pos(slider_x + slider_w + 12, cy)
    ass:an(4)
    ass:append(string.format(
        "{\\fn%s\\fs13\\bord1\\shad0\\1c&H%s&\\3c&H000000&}",
        font, muted and "555555" or "CCCCCC"))
    ass:append(string.format("%d%%", math.floor(vol)))
end

return VolumeButton
