local mp = require 'mp'
local Element = require 'elements.Element'
local WindowControls = setmetatable({}, {__index = Element})
WindowControls.__index = WindowControls

local BTN_GAP = 30
local HITBOX = 20

function WindowControls.new(state, opts)
    local self = Element.new(state, opts)
    return setmetatable(self, WindowControls)
end

function WindowControls:handle_input(event, x, y)
    if event ~= "down" then return false end
    if not self.opts.show_window_controls then return false end
    local cy = self.state.h - self.opts.controls_y_offset
    if y < self.state.h - self.opts.box_height then return false end
    local w = self.state.w

    -- Fullscreen (rightmost)
    if math.abs(x - (w - 25)) < HITBOX and math.abs(y - cy) < HITBOX then
        mp.commandv("cycle", "fullscreen")
        return true
    end
    -- Minimize
    if math.abs(x - (w - 25 - BTN_GAP)) < HITBOX and math.abs(y - cy) < HITBOX then
        mp.commandv("cycle", "window-minimized")
        return true
    end
    return false
end

function WindowControls:draw(ass)
    if not self.opts.show_window_controls then return end
    local cy = self.state.h - self.opts.controls_y_offset
    local w = self.state.w

    -- Fullscreen icon (all drawn centered at cy with an(5))
    local fs_x = w - 25
    local is_fs = mp.get_property_bool("fullscreen", false)

    ass:new_event()
    ass:pos(fs_x, cy)
    ass:an(5)
    ass:append("{\\bord1\\shad0\\1c&HFFFFFF&\\3c&H000000&}")
    ass:draw_start()
    local s = 7
    local t = 2
    if is_fs then
        -- Shrink corners
        ass:rect_cw(-s, -s, -s + 4, -s + t)
        ass:rect_cw(-s, -s, -s + t, -s + 4)
        ass:rect_cw(s - 4, s - t, s, s)
        ass:rect_cw(s - t, s - 4, s, s)
    else
        -- Expand corners
        ass:rect_cw(-s, -s, -s + 4, -s + t)
        ass:rect_cw(-s, -s, -s + t, -s + 4)
        ass:rect_cw(s - 4, -s, s, -s + t)
        ass:rect_cw(s - t, -s, s, -s + 4)
        ass:rect_cw(-s, s - t, -s + 4, s)
        ass:rect_cw(-s, s - 4, -s + t, s)
        ass:rect_cw(s - 4, s - t, s, s)
        ass:rect_cw(s - t, s - 4, s, s)
    end
    ass:draw_stop()

    -- Minimize icon (centered at cy)
    local min_x = w - 25 - BTN_GAP
    ass:new_event()
    ass:pos(min_x, cy)
    ass:an(5)
    ass:append("{\\bord1\\shad0\\1c&HFFFFFF&\\3c&H000000&}")
    ass:draw_start()
    ass:rect_cw(-7, -1, 7, 1)
    ass:draw_stop()
end

return WindowControls
